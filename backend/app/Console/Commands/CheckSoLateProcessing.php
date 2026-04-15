<?php

namespace App\Console\Commands;

use App\Enums\UserRole;
use App\Models\HrdViolation;
use App\Models\Order;
use App\Models\SystemThreshold;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class CheckSoLateProcessing extends Command
{
    protected $signature   = 'hrd:check-so-late-processing';
    protected $description = 'Detect orders that have been pending too long without SO confirmation.';

    public function handle(): void
    {
        $maxMinutes = SystemThreshold::getValue('so_max_processing_minutes', 30);

        Order::where('status', 'pending')
            ->whereNotNull('created_at')
            ->get()
            ->each(function (Order $order) use ($maxMinutes) {
                $minutesPending = Carbon::parse($order->created_at)->diffInMinutes(now());

                if ($minutesPending < $maxMinutes) {
                    return;
                }

                // Cek duplikat
                $exists = HrdViolation::where('order_id', $order->id)
                    ->where('violation_type', 'so_late_processing')
                    ->exists();

                if ($exists) {
                    return;
                }

                $severity = $minutesPending > ($maxMinutes * 2) ? 'medium' : 'low';

                $soUserId = $order->so_user_id;
                // Jika belum ada SO yang ambil, buat violation terhadap role
                if (!$soUserId) {
                    // Notif ke semua SO saja tanpa violation user spesifik
                    NotificationService::sendToRole(UserRole::SERVICE_OFFICER->value, 'ALARM',
                        '⚠ Order Menunggu Konfirmasi',
                        "Order {$order->order_number} sudah {$minutesPending} menit belum dikonfirmasi!",
                        ['order_id' => $order->id, 'action' => 'confirm_order']
                    );
                    return;
                }

                $violation = HrdViolation::create([
                    'violated_by'     => $soUserId,
                    'order_id'        => $order->id,
                    'violation_type'  => 'so_late_processing',
                    'description'     => "SO terlambat konfirmasi order {$order->order_number}. Sudah {$minutesPending} menit (maks {$maxMinutes} menit).",
                    'threshold_value' => $maxMinutes,
                    'actual_value'    => $minutesPending,
                    'severity'        => $severity,
                    'status'          => 'new',
                ]);

                NotificationService::sendHrdViolationAlert($violation);
                $this->warn("SO late: order {$order->order_number} — {$minutesPending} menit");
            });

        $this->info('SO late processing check selesai.');
    }
}
