<?php

namespace App\Console\Commands;

use App\Enums\AttendanceStatus;
use App\Enums\NotificationPriority;
use App\Enums\UserRole;
use App\Enums\ViolationType;
use App\Models\FieldAttendance;
use App\Models\HrdViolation;
use App\Models\SystemThreshold;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class CheckAttendanceLate extends Command
{
    protected $signature   = 'attendance:check-late';
    protected $description = 'Mark absent and alert HRD if vendor/tukang_foto not checked in after threshold.';

    public function handle(): void
    {
        $thresholdMinutes = SystemThreshold::getValue('attendance_late_threshold_minutes', 30);

        $scheduled = FieldAttendance::where('status', AttendanceStatus::SCHEDULED->value)
            ->whereNotNull('scheduled_jam')
            ->whereDate('attendance_date', today())
            ->with('user:id,name,role')
            ->get();

        foreach ($scheduled as $attendance) {
            $scheduledTime = Carbon::parse($attendance->attendance_date)
                ->setTimeFromTimeString($attendance->scheduled_jam);

            if (now()->lessThan($scheduledTime->copy()->addMinutes($thresholdMinutes))) {
                continue;
            }

            // Mark absent
            $attendance->update(['status' => AttendanceStatus::ABSENT->value]);

            // Create HRD violation (no duplicate per attendance per day)
            $exists = HrdViolation::where('violated_by', $attendance->user_id)
                ->where('violation_type', ViolationType::VENDOR_ATTENDANCE_LATE->value)
                ->whereDate('created_at', today())
                ->where('related_order_id', $attendance->order_id)
                ->exists();

            if ($exists) continue;

            HrdViolation::create([
                'violated_by' => $attendance->user_id,
                'violation_type' => ViolationType::VENDOR_ATTENDANCE_LATE->value,
                'related_order_id' => $attendance->order_id,
                'description' => "{$attendance->user->name} ({$attendance->role}) tidak hadir untuk '{$attendance->kegiatan}' pada {$attendance->attendance_date}",
                'severity' => ViolationType::VENDOR_ATTENDANCE_LATE->severity(),
            ]);

            NotificationService::send(UserRole::HRD->value, NotificationPriority::ALARM->value, 'Vendor Tidak Hadir!',
                "{$attendance->user->name} tidak check-in untuk order {$attendance->order_id}");
            NotificationService::send(UserRole::OWNER->value, NotificationPriority::HIGH->value, 'Vendor No-Show',
                "{$attendance->user->name} ({$attendance->role}) tidak hadir");
        }

        $this->info('Attendance late check completed.');
    }
}
