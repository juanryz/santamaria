<?php

namespace App\Http\Controllers\Attendance;

use App\Enums\ViolationType;
use App\Http\Controllers\Controller;
use App\Models\AttendanceLocation;
use App\Models\AttendanceLog;
use App\Models\DailyAttendance;
use App\Models\HrdViolation;
use App\Models\UserShiftAssignment;
use App\Models\WorkShift;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DailyAttendanceController extends Controller
{
    /**
     * POST /attendance/clock-in — Geofence-validated clock in with selfie.
     */
    public function clockIn(Request $request)
    {
        $request->validate([
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'selfie_path' => 'nullable|string',
            'is_mock_provider' => 'boolean',
            'device_info' => 'nullable|string',
        ]);

        $userId = $request->user()->id;
        $today = now()->toDateString();

        // Check if already clocked in
        $existing = DailyAttendance::where('user_id', $userId)->where('attendance_date', $today)->first();
        if ($existing && $existing->clock_in_at) {
            return $this->error('Sudah clock-in hari ini', 422);
        }

        // Get shift assignment
        $assignment = UserShiftAssignment::where('user_id', $userId)
            ->where('is_active', true)
            ->where('effective_from', '<=', $today)
            ->where(fn($q) => $q->whereNull('effective_until')->orWhere('effective_until', '>=', $today))
            ->with(['shift', 'location'])
            ->first();

        $shift = $assignment?->shift;
        $location = $assignment?->location;

        // Layer 1: Mock detection
        $isMock = $request->boolean('is_mock_provider', false);

        // Layer 5: Geofence validation
        $distance = null;
        $isWithinRadius = true;
        if ($location) {
            $distance = $this->haversineDistance(
                $request->latitude, $request->longitude,
                $location->latitude, $location->longitude
            );
            $isWithinRadius = $distance <= $location->radius_meters;
        }

        // Log the attempt
        AttendanceLog::create([
            'user_id' => $userId,
            'action' => 'clock_in',
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'distance_meters' => $distance,
            'is_within_radius' => $isWithinRadius,
            'is_mock' => $isMock,
            'device_info' => $request->device_info,
        ]);

        // Block if mock detected
        if ($isMock) {
            HrdViolation::create([
                'violated_by' => $userId,
                'violation_type' => 'mock_location_attempt',
                'description' => "Mock GPS terdeteksi saat clock-in: lat={$request->latitude}, lng={$request->longitude}",
                'severity' => 'high',
            ]);
            NotificationService::send('HRD', 'ALARM', 'Mock GPS Terdeteksi!',
                "{$request->user()->name} mencoba clock-in dengan fake GPS");

            return $this->error('Lokasi palsu terdeteksi. Clock-in ditolak.', 403);
        }

        // Block if outside radius
        if (!$isWithinRadius) {
            return $this->error(
                "Anda berada {$distance}m dari lokasi. Maks {$location->radius_meters}m.",
                422,
                ['distance' => $distance, 'max_radius' => $location->radius_meters]
            );
        }

        // Determine late status
        $status = 'present';
        if ($shift) {
            $shiftStart = Carbon::parse($today . ' ' . $shift->start_time);
            $lateTolerance = $shiftStart->copy()->addMinutes($shift->late_tolerance_minutes);

            if (now()->greaterThan($lateTolerance)) {
                $status = 'late';

                HrdViolation::create([
                    'violated_by' => $userId,
                    'violation_type' => 'daily_attendance_late',
                    'description' => "Clock-in terlambat: " . now()->format('H:i') . " (shift mulai: {$shift->start_time})",
                    'severity' => 'low',
                ]);
            }
        }

        // Create or update attendance
        $attendance = DailyAttendance::updateOrCreate(
            ['user_id' => $userId, 'attendance_date' => $today],
            [
                'shift_id' => $shift?->id,
                'location_id' => $location?->id,
                'status' => $status,
                'clock_in_at' => now(),
                'clock_in_lat' => $request->latitude,
                'clock_in_lng' => $request->longitude,
                'clock_in_distance_meters' => $distance,
                'clock_in_selfie_path' => $request->selfie_path,
            ]
        );

        return $this->success($attendance, $status === 'late' ? 'Clock-in berhasil (terlambat)' : 'Clock-in berhasil');
    }

    /**
     * POST /attendance/clock-out
     */
    public function clockOut(Request $request)
    {
        $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'selfie_path' => 'nullable|string',
        ]);

        $userId = $request->user()->id;
        $attendance = DailyAttendance::where('user_id', $userId)
            ->where('attendance_date', now()->toDateString())
            ->first();

        if (!$attendance || !$attendance->clock_in_at) {
            return $this->error('Belum clock-in hari ini', 422);
        }
        if ($attendance->clock_out_at) {
            return $this->error('Sudah clock-out hari ini', 422);
        }

        // Calculate work hours
        $workHours = Carbon::parse($attendance->clock_in_at)->diffInMinutes(now()) / 60;

        // Check early leave
        $shift = $attendance->shift;
        if ($shift) {
            $shiftEnd = Carbon::parse(now()->toDateString() . ' ' . $shift->end_time);
            $earlyTolerance = $shiftEnd->copy()->subMinutes($shift->early_leave_tolerance_minutes);

            if (now()->lessThan($earlyTolerance)) {
                // Still record clock-out but flag
                $attendance->update(['status' => 'early_leave']);
                HrdViolation::create([
                    'violated_by' => $userId,
                    'violation_type' => 'daily_attendance_early_leave',
                    'description' => "Clock-out lebih awal: " . now()->format('H:i') . " (shift selesai: {$shift->end_time})",
                    'severity' => 'low',
                ]);
            }
        }

        // Geofence for clock-out
        $location = $attendance->location;
        $distance = null;
        if ($location) {
            $distance = $this->haversineDistance(
                $request->latitude, $request->longitude,
                $location->latitude, $location->longitude
            );
        }

        $attendance->update([
            'clock_out_at' => now(),
            'clock_out_lat' => $request->latitude,
            'clock_out_lng' => $request->longitude,
            'clock_out_distance_meters' => $distance,
            'clock_out_selfie_path' => $request->selfie_path,
            'work_hours' => round($workHours, 2),
        ]);

        AttendanceLog::create([
            'user_id' => $userId,
            'action' => 'clock_out',
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'distance_meters' => $distance,
        ]);

        return $this->success($attendance->fresh(), 'Clock-out berhasil. Durasi kerja: ' . round($workHours, 1) . ' jam');
    }

    /**
     * GET /attendance/me/today
     */
    public function today(Request $request)
    {
        $attendance = DailyAttendance::with(['shift', 'location'])
            ->where('user_id', $request->user()->id)
            ->where('attendance_date', now()->toDateString())
            ->first();

        $assignment = UserShiftAssignment::where('user_id', $request->user()->id)
            ->where('is_active', true)
            ->with(['shift', 'location'])
            ->first();

        return $this->success([
            'attendance' => $attendance,
            'assignment' => $assignment,
            'server_time' => now()->toIso8601String(),
        ]);
    }

    /**
     * GET /attendance/me — My attendance history.
     */
    public function myHistory(Request $request)
    {
        $month = $request->input('month', now()->format('Y-m'));

        $attendances = DailyAttendance::where('user_id', $request->user()->id)
            ->where('attendance_date', 'like', "$month%")
            ->with('shift')
            ->orderBy('attendance_date', 'desc')
            ->get();

        $summary = [
            'total_days' => $attendances->count(),
            'present' => $attendances->where('status', 'present')->count(),
            'late' => $attendances->where('status', 'late')->count(),
            'absent' => $attendances->where('status', 'absent')->count(),
            'early_leave' => $attendances->where('status', 'early_leave')->count(),
            'avg_work_hours' => round($attendances->avg('work_hours'), 1),
        ];

        return $this->success(['attendances' => $attendances, 'summary' => $summary]);
    }

    private function haversineDistance(float $lat1, float $lon1, float $lat2, float $lon2): int
    {
        $earthRadius = 6371000;
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat / 2) * sin($dLat / 2) +
            cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
            sin($dLon / 2) * sin($dLon / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return (int) round($earthRadius * $c);
    }
}
