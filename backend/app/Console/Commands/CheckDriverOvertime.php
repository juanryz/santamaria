<?php

namespace App\Console\Commands;

use App\Models\DriverSession;
use App\Models\HrdViolation;
use App\Models\SystemThreshold;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class CheckDriverOvertime extends Command
{
    protected $signature   = 'hrd:check-driver-overtime';
    protected $description = 'Detect drivers who have been On Duty beyond the allowed hours.';

    public function handle(): void
    {
        $maxHours = SystemThreshold::getValue('driver_max_duty_hours', 12);

        $activeSessions = DriverSession::with('driver:id,name,role')
            ->whereNull('ended_at')
            ->get();

        foreach ($activeSessions as $session) {
            $hoursOnDuty = Carbon::parse($session->started_at)->diffInHours(now(), true);

            if ($hoursOnDuty > $maxHours) {
                // Cek agar tidak duplikat — hanya buat 1 violation per session per hari
                $exists = HrdViolation::where('violated_by', $session->driver_id)
                    ->where('violation_type', 'driver_overtime')
                    ->whereDate('created_at', today())
                    ->exists();

                if ($exists) {
                    continue;
                }

                $violation = HrdViolation::create([
                    'violated_by'     => $session->driver_id,
                    'violation_type'  => 'driver_overtime',
                    'description'     => "Driver {$session->driver->name} On Duty sudah {$hoursOnDuty} jam (maks {$maxHours} jam).",
                    'threshold_value' => $maxHours,
                    'actual_value'    => $hoursOnDuty,
                    'severity'        => $hoursOnDuty > ($maxHours * 1.5) ? 'high' : 'medium',
                    'status'          => 'new',
                ]);

                NotificationService::sendHrdViolationAlert($violation);
                $this->warn("Driver overtime: {$session->driver->name} — {$hoursOnDuty} jam");
            }
        }

        $this->info('Driver overtime check selesai.');
    }
}
