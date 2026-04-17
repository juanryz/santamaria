<?php

namespace App\Console\Commands;

use App\Models\Order;
use App\Services\NotificationService;
use Illuminate\Console\Command;

class SendPaymentReminders extends Command
{
    protected $signature = 'payment:send-reminders';
    protected $description = 'Send payment reminders to consumers for completed but unpaid orders';

    public function handle(): void
    {
        $orders = Order::where('status', Order::STATUS_COMPLETED)
            ->where('payment_status', Order::PAYMENT_STATUS_UNPAID)
            ->whereNotNull('completed_at')
            ->get();

        $now = now();

        foreach ($orders as $order) {
            $hoursSinceCompleted = $now->diffInHours($order->completed_at);

            if ($hoursSinceCompleted >= 72) {
                // 3+ days — escalate to Purchasing + Owner
                $this->sendIfNotRecentlySent($order, 'escalation', function () use ($order) {
                    NotificationService::sendToRole('purchasing', 'ALARM',
                        "Consumer Belum Bayar 3+ Hari — {$order->order_number}",
                        "Order {$order->order_number} ({$order->deceased_name}) selesai sejak " .
                        $order->completed_at->format('d/m/Y H:i') . ". Consumer belum melakukan pembayaran."
                    );
                    NotificationService::sendToRole('owner', 'HIGH',
                        "Eskalasi: Belum Bayar — {$order->order_number}",
                        "Order sudah 3 hari lebih belum dibayar. Follow up diperlukan."
                    );
                });
            } elseif ($hoursSinceCompleted >= 48) {
                // 2+ days — urgent reminder
                $this->sendIfNotRecentlySent($order, 'reminder_2', function () use ($order) {
                    if ($order->pic_user_id) {
                        NotificationService::send($order->pic_user_id, 'HIGH',
                            'Pengingat Pembayaran',
                            "Pembayaran untuk layanan {$order->deceased_name} belum kami terima. " .
                            "Mohon segera lakukan pembayaran melalui aplikasi."
                        );
                    }
                });
            } elseif ($hoursSinceCompleted >= 24) {
                // 1+ day — first reminder
                $this->sendIfNotRecentlySent($order, 'reminder_1', function () use ($order) {
                    if ($order->pic_user_id) {
                        NotificationService::send($order->pic_user_id, 'NORMAL',
                            'Pengingat Pembayaran',
                            "Layanan untuk {$order->deceased_name} telah selesai. " .
                            "Silakan lakukan pembayaran melalui aplikasi Santa Maria."
                        );
                    }
                });
            }
        }

        $this->info("Checked {$orders->count()} unpaid completed orders.");
    }

    /**
     * Prevent duplicate reminders by using a simple cache key per order per reminder stage.
     * Each stage key expires after 20 hours so reminders don't re-fire within the same window.
     */
    private function sendIfNotRecentlySent(Order $order, string $stage, callable $send): void
    {
        $cacheKey = "payment_reminder:{$order->id}:{$stage}";

        if (cache()->has($cacheKey)) {
            return;
        }

        $send();

        cache()->put($cacheKey, true, now()->addHours(20));
    }
}
