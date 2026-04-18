<?php

namespace App\Console\Commands;

use App\Models\ConsumerPaymentReminder;
use App\Models\Order;
use App\Models\SystemThreshold;
use App\Services\NotificationService;
use Illuminate\Console\Command;

/**
 * v1.40 — Consumer payment reminder harian untuk order yang lewat deadline bayar.
 *
 * Deadline awal: 3 hari setelah completed.
 * Toleransi:     7 hari (H+4 .. H+10) → reminder harian, severity escalating.
 * H+11+:         Eskalasi ke Purchasing + Owner.
 *
 * Log setiap reminder di consumer_payment_reminders untuk audit trail.
 */
class SendConsumerPaymentReminders extends Command
{
    protected $signature = 'consumer-payment:send-reminders';
    protected $description = 'Kirim reminder harian pembayaran consumer H+4..H+10 (v1.40)';

    public function handle(): void
    {
        $deadlineDays = 3; // Deadline awal
        $graceDays = (int) SystemThreshold::getValue('consumer_payment_grace_days_after_deadline', 7);
        $totalMax = (int) SystemThreshold::getValue('consumer_payment_total_max_days', 10);

        $orders = Order::where('status', 'completed')
            ->where('payment_status', '!=', 'paid')
            ->where('payment_status', '!=', 'verified')
            ->whereNotNull('completed_at')
            ->get();

        $now = now();
        $sentCount = 0;
        $escalatedCount = 0;

        foreach ($orders as $order) {
            $daysSinceCompleted = (int) $order->completed_at->diffInDays($now);

            // Masih dalam deadline awal (≤ 3 hari) — skip
            if ($daysSinceCompleted <= $deadlineDays) {
                continue;
            }

            // Reminder day = hari ke berapa dalam masa toleransi (1..graceDays)
            $reminderDay = $daysSinceCompleted; // 4, 5, 6, ..., 10, 11+

            // Cek sudah ada reminder hari ini?
            $alreadySent = ConsumerPaymentReminder::where('order_id', $order->id)
                ->where('reminder_day', $reminderDay)
                ->exists();

            if ($alreadySent) {
                continue;
            }

            // H+11 keatas — eskalasi
            if ($daysSinceCompleted > $totalMax) {
                $this->escalate($order, $daysSinceCompleted, $reminderDay);
                $escalatedCount++;
                continue;
            }

            // H+4..H+10 — reminder harian (escalating severity)
            $this->sendReminder($order, $reminderDay, $daysSinceCompleted);
            $sentCount++;
        }

        $this->info("Consumer payment reminders: {$sentCount} sent, {$escalatedCount} escalated.");
    }

    private function sendReminder(Order $order, int $reminderDay, int $daysSinceCompleted): void
    {
        // Severity meningkat sesuai hari
        $severity = match (true) {
            $daysSinceCompleted >= 9 => 'ALARM',
            $daysSinceCompleted >= 6 => 'HIGH',
            default => 'NORMAL',
        };

        $title = 'Pengingat Pembayaran — Hari ke-' . $daysSinceCompleted;
        $body = "Pembayaran untuk layanan {$order->deceased_name} ({$order->order_number}) " .
                "telah lewat {$daysSinceCompleted} hari. Mohon segera lakukan pembayaran.";

        if ($order->pic_user_id) {
            NotificationService::send($order->pic_user_id, $severity, $title, $body);
        }

        ConsumerPaymentReminder::create([
            'order_id' => $order->id,
            'reminder_day' => $reminderDay,
            'reminder_date' => now()->toDateString(),
            'sent_via' => 'app_notif',
            'recipient_phone' => $order->consumer_phone ?? null,
            'template_used' => 'ORDER_PAYMENT_REMINDER',
            'message_content' => $body,
            'created_at' => now(),
        ]);
    }

    private function escalate(Order $order, int $daysSinceCompleted, int $reminderDay): void
    {
        NotificationService::sendToRole('purchasing', 'ALARM',
            "Eskalasi — {$order->order_number} ({$daysSinceCompleted} hari)",
            "Consumer belum bayar {$daysSinceCompleted} hari sejak order selesai. Follow up manual diperlukan."
        );
        NotificationService::sendToRole('owner', 'HIGH',
            "Consumer Overdue — {$order->order_number}",
            "{$daysSinceCompleted} hari belum bayar. Order: {$order->deceased_name}."
        );

        ConsumerPaymentReminder::create([
            'order_id' => $order->id,
            'reminder_day' => $reminderDay,
            'reminder_date' => now()->toDateString(),
            'sent_via' => 'app_notif',
            'template_used' => 'ORDER_PAYMENT_ESCALATION',
            'message_content' => "Escalation day {$daysSinceCompleted}",
            'created_at' => now(),
        ]);
    }
}
