<?php

namespace App\Console\Commands;

use App\Models\HrdViolation;
use App\Models\SystemThreshold;
use App\Models\VendorPerformance;
use App\Services\NotificationService;
use Illuminate\Console\Command;

class CheckVendorRepeatedReject extends Command
{
    protected $signature   = 'hrd:check-vendor-repeated-reject';
    protected $description = 'Detect vendors who have repeatedly rejected assignments this month.';

    public function handle(): void
    {
        $maxReject = (int) SystemThreshold::getValue('vendor_max_reject_count_monthly', 3);

        $rejectCounts = VendorPerformance::where('status', 'rejected')
            ->whereMonth('created_at', now()->month)
            ->whereYear('created_at', now()->year)
            ->selectRaw('vendor_user_id, COUNT(*) as reject_count')
            ->groupBy('vendor_user_id')
            ->having('reject_count', '>=', $maxReject)
            ->get();

        foreach ($rejectCounts as $row) {
            $exists = HrdViolation::where('violated_by', $row->vendor_user_id)
                ->where('violation_type', 'vendor_repeated_reject')
                ->whereMonth('created_at', now()->month)
                ->whereYear('created_at', now()->year)
                ->exists();

            if ($exists) {
                continue;
            }

            $vendor = \App\Models\User::find($row->vendor_user_id);

            $violation = HrdViolation::create([
                'violated_by'     => $row->vendor_user_id,
                'violation_type'  => 'vendor_repeated_reject',
                'description'     => "Vendor {$vendor->name} menolak assignment {$row->reject_count}x bulan ini (maks {$maxReject}x).",
                'threshold_value' => $maxReject,
                'actual_value'    => $row->reject_count,
                'severity'        => 'high',
                'status'          => 'new',
            ]);

            NotificationService::sendHrdViolationAlert($violation);
            $this->warn("Vendor repeated reject: {$vendor->name} — {$row->reject_count}x");
        }

        $this->info('Vendor repeated reject check selesai.');
    }
}
