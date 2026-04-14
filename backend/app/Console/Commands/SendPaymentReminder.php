<?php

namespace App\Console\Commands;

use App\Models\Order;
use App\Models\SystemThreshold;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class SendPaymentReminder extends Command
{
    protected $signature   = 'order:send-payment-reminder';
    protected $description = 'Send periodic reminders to consumers who have not uploaded payment proof.';

    public function handle(): void
    {
        $intervalHours = SystemThreshold::getValue('consumer_payment_reminder_hours', 24);
        $maxReminders  = 3;

        Order::where('status', 'completed')
            ->where('payment_status', 'unpaid')
            ->whereNotNull('pic_user_id')
            ->whereNotNull('completed_at')
            ->get()
            ->each(function (Order $order) use ($intervalHours, $maxReminders) {
                $hoursAfter = Carbon::parse($order->completed_at)->diffInHours(now());

                // Hitung berapa kali seharusnya sudah diingatkan
                $dueReminders = (int) floor($hoursAfter / $intervalHours);

                if ($dueReminders === 0 || $dueReminders > $maxReminders) {
                    // Lebih dari maxReminders: Finance follow-up manual
                    if ($dueReminders > $maxReminders) {
                        NotificationService::sendToRole('finance', 'ALARM',
                            'Follow Up Payment Konsumen',
                            "Konsumen order {$order->order_number} belum upload bukti payment setelah {$hoursAfter} jam. Hubungi langsung.",
                            ['order_id' => $order->id]
                        );
                    }
                    return;
                }

                // Kirim reminder ke consumer
                NotificationService::send(
                    $order->pic_user_id,
                    'HIGH',
                    'Pengingat Pembayaran',
                    "Order {$order->order_number} menunggu konfirmasi pembayaran. Silakan upload bukti transfer/cash melalui aplikasi.",
                    ['order_id' => $order->id, 'action' => 'upload_payment_proof']
                );

                $this->info("Reminder sent: order {$order->order_number}");
            });
    }
}
