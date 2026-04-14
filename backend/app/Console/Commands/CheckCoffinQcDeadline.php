<?php

namespace App\Console\Commands;

use App\Enums\NotificationPriority;
use App\Enums\UserRole;
use App\Enums\ViolationType;
use App\Models\CoffinOrder;
use App\Models\HrdViolation;
use App\Models\SystemThreshold;
use App\Services\NotificationService;
use Illuminate\Console\Command;

class CheckCoffinQcDeadline extends Command
{
    protected $signature   = 'coffin:check-qc-deadline';
    protected $description = 'Alert if coffin QC overdue after finishing completion.';

    public function handle(): void
    {
        $deadlineHours = SystemThreshold::getValue(ViolationType::COFFIN_QC_OVERDUE->thresholdKey(), 48);

        $overdue = CoffinOrder::where('status', 'amplas_done')
            ->whereNotNull('selesai_finishing')
            ->where('selesai_finishing', '<=', now()->subHours($deadlineHours))
            ->get();

        foreach ($overdue as $coffin) {
            $exists = HrdViolation::where('violation_type', ViolationType::COFFIN_QC_OVERDUE->value)
                ->where('description', 'LIKE', "%{$coffin->coffin_order_number}%")
                ->whereDate('created_at', today())
                ->exists();

            if ($exists) continue;

            HrdViolation::create([
                'violation_type' => ViolationType::COFFIN_QC_OVERDUE->value,
                'description' => "Peti {$coffin->coffin_order_number} (kode: {$coffin->kode_peti}) belum di-QC setelah {$deadlineHours} jam",
                'severity' => ViolationType::COFFIN_QC_OVERDUE->severity(),
            ]);

            NotificationService::send(UserRole::GUDANG->value, NotificationPriority::ALARM->value, 'QC Peti Overdue!',
                "Peti {$coffin->coffin_order_number} perlu segera di-QC");
        }

        $this->info("Coffin QC deadline check done. Found {$overdue->count()} overdue.");
    }
}
