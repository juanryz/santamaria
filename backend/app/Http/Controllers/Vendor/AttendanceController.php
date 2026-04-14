<?php

namespace App\Http\Controllers\Vendor;

use App\Http\Controllers\Controller;
use App\Models\FieldAttendance;
use App\Models\Order;
use App\Models\SystemThreshold;
use App\Events\AttendanceUpdated;
use Carbon\Carbon;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    public function checkIn(Request $request, $id)
    {
        $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
        ]);

        $attendance = FieldAttendance::where('user_id', $request->user()->id)->findOrFail($id);

        if ($attendance->status !== 'scheduled') {
            return response()->json(['success' => false, 'message' => 'Sudah check-in atau ditandai'], 422);
        }

        // Geofence validation — check distance to order location
        $order = Order::find($attendance->order_id);
        if ($order && $order->destination_lat && $order->destination_lng) {
            $radiusMeters = (int) (SystemThreshold::getValue('attendance_radius_meters', 500));
            $distance = $this->haversineDistance(
                $request->latitude, $request->longitude,
                $order->destination_lat, $order->destination_lng
            );

            if ($distance > $radiusMeters) {
                return response()->json([
                    'success' => false,
                    'message' => "Anda berada {$distance}m dari lokasi. Maksimal {$radiusMeters}m untuk check-in.",
                    'distance' => $distance,
                    'max_radius' => $radiusMeters,
                ], 422);
            }
        }

        // Early check-in prevention
        if ($attendance->scheduled_jam) {
            $earlyMinutes = (int) (SystemThreshold::getValue('attendance_checkin_early_minutes', 120));
            $scheduledTime = Carbon::parse($attendance->attendance_date)->setTimeFromTimeString($attendance->scheduled_jam);
            $earliestAllowed = $scheduledTime->copy()->subMinutes($earlyMinutes);

            if (now()->lessThan($earliestAllowed)) {
                return response()->json([
                    'success' => false,
                    'message' => "Check-in terlalu awal. Paling cepat {$earliestAllowed->format('H:i')}.",
                ], 422);
            }
        }

        // Late detection
        $isLate = false;
        if ($attendance->scheduled_jam) {
            $lateThreshold = (int) (SystemThreshold::getValue('attendance_late_threshold_minutes', 30));
            $scheduledTime = Carbon::parse($attendance->attendance_date)->setTimeFromTimeString($attendance->scheduled_jam);
            $isLate = now()->greaterThan($scheduledTime->copy()->addMinutes($lateThreshold));
        }

        $attendance->update([
            'arrived_at' => now(),
            'status' => $isLate ? 'late' : 'present',
        ]);

        event(new AttendanceUpdated(
            $attendance->order_id,
            $attendance->user_id,
            $attendance->status,
            $attendance->role,
        ));

        return response()->json([
            'success' => true,
            'message' => $isLate ? 'Check-in (terlambat)' : 'Check-in berhasil',
            'data' => $attendance,
        ]);
    }

    public function checkOut(Request $request, $id)
    {
        $attendance = FieldAttendance::where('user_id', $request->user()->id)->findOrFail($id);

        if (!in_array($attendance->status, ['present', 'late'])) {
            return response()->json(['success' => false, 'message' => 'Belum check-in'], 422);
        }

        $attendance->update(['departed_at' => now()]);

        event(new AttendanceUpdated(
            $attendance->order_id,
            $attendance->user_id,
            'departed',
            $attendance->role,
        ));

        return response()->json(['success' => true, 'message' => 'Check-out berhasil', 'data' => $attendance]);
    }

    /**
     * Haversine formula — distance in meters between two lat/lng points.
     */
    private function haversineDistance(float $lat1, float $lon1, float $lat2, float $lon2): int
    {
        $earthRadius = 6371000; // meters

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
            cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
            sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return (int) round($earthRadius * $c);
    }
}
