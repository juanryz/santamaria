<?php

namespace App\Console\Commands;

use App\Enums\NotificationPriority;
use App\Enums\OrderStatus;
use App\Enums\ViolationType;
use App\Models\Order;
use App\Models\OrderDeathCertificateDoc;
use App\Models\HrdViolation;
use App\Models\SystemThreshold;
use App\Services\NotificationService;
use Illuminate\Console\Command;

class CheckDeathCertPending extends Command
{
    protected $signature   = 'death-cert:check-pending';
    protected $description = 'Reminder if death certificate checklist not created after order completion.';

    public function handle(): void
    {
        $deadlineHours = SystemThreshold::getValue(ViolationType::DEATH_CERT_NOT_SUBMITTED->thresholdKey(), 24);

        $completedOrders = Order::where('status', OrderStatus::COMPLETED->value)
            ->where('death_cert_submitted', false)
            ->where('updated_at', '<=', now()->subHours($deadlineHours))
            ->get();

        foreach ($completedOrders as $order) {
            $hasChecklist = OrderDeathCertificateDoc::where('order_id', $order->id)->exists();
            if ($hasChecklist) continue;

            $exists = HrdViolation::where('violation_type', ViolationType::DEATH_CERT_NOT_SUBMITTED->value)
                ->where('related_order_id', $order->id)
                ->whereDate('created_at', today())
                ->exists();

            if ($exists) continue;

            HrdViolation::create([
                'violation_type' => ViolationType::DEATH_CERT_NOT_SUBMITTED->value,
                'related_order_id' => $order->id,
                'description' => "Berkas akta kematian untuk order {$order->order_number} belum dibuat setelah {$deadlineHours} jam",
                'severity' => ViolationType::DEATH_CERT_NOT_SUBMITTED->severity(),
            ]);

            if ($order->so_user_id) {
                NotificationService::send($order->so_user_id, NotificationPriority::NORMAL->value, 'Berkas Akta Kematian',
                    "Segera buat checklist berkas akta kematian untuk order {$order->order_number}");
            }
        }

        $this->info("Death cert check done. Found {$completedOrders->count()} pending.");
    }
}
