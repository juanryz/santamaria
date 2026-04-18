<?php

namespace App\Console\Commands;

use App\Models\HrdViolation;
use App\Models\OrderDeathCertProgress;
use App\Models\SystemThreshold;
use App\Services\NotificationService;
use Illuminate\Console\Command;

/**
 * v1.40 — Cek akta kematian yang lewat 2 minggu.
 * Max 14 hari dari started_at hingga handed_to_family.
 * Lewat → alarm HRD + Owner, catat HRD violation.
 */
class CheckDeathCertOverdue extends Command
{
    protected $signature = 'death-cert:check-overdue';
    protected $description = 'Cek akta kematian yang lewat threshold 2 minggu (v1.40)';

    public function handle(): void
    {
        $maxDays = (int) SystemThreshold::getValue('death_cert_max_processing_days', 14);

        $overdueRecords = OrderDeathCertProgress::with(['order:id,order_number,deceased_name', 'petugasAkta:id,name'])
            ->whereNotIn('current_stage', ['handed_to_family'])
            ->whereNotNull('started_at')
            ->where('started_at', '<=', now()->subDays($maxDays))
            ->get();

        $count = 0;
        foreach ($overdueRecords as $progress) {
            $days = (int) $progress->started_at->diffInDays(now());

            // Idempotent: skip jika sudah ada violation hari ini
            $exists = HrdViolation::where('related_order_id', $progress->order_id)
                ->where('violation_type', 'death_cert_not_submitted')
                ->whereDate('created_at', today())
                ->exists();

            if ($exists) {
                continue;
            }

            HrdViolation::create([
                'violation_type' => 'death_cert_not_submitted',
                'related_order_id' => $progress->order_id,
                'violated_by' => $progress->petugas_akta_id,
                'description' => "Akta kematian untuk order {$progress->order?->order_number} " .
                                 "sudah {$days} hari belum selesai (max {$maxDays} hari). " .
                                 "Stage saat ini: {$progress->current_stage}.",
                'severity' => 'high',
            ]);

            NotificationService::sendToRole('hrd', 'ALARM',
                "Akta Overdue — {$progress->order?->order_number}",
                "Akta {$progress->order?->deceased_name} sudah {$days} hari belum selesai."
            );
            NotificationService::sendToRole('owner', 'HIGH',
                "Akta Overdue — {$progress->order?->order_number}",
                "Petugas: " . ($progress->petugasAkta?->name ?? '-') . " | Stage: {$progress->current_stage}"
            );

            $progress->update(['days_elapsed' => $days]);
            $count++;
        }

        $this->info("Death cert overdue check: {$count} records flagged.");
    }
}
