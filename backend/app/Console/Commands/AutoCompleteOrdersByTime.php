<?php

namespace App\Console\Commands;

use App\Models\Order;
use App\Models\OrderStatusLog;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class AutoCompleteOrdersByTime extends Command
{
    protected $signature   = 'order:auto-complete-by-time';
    protected $description = 'Auto-complete orders where time has passed and driver has arrived at destination.';

    public function handle(): void
    {
        $now = now();

        // Auto-complete: jam sudah lewat + driver sudah tiba
        Order::where('status', 'in_progress')
            ->whereNotNull('scheduled_at')
            ->whereNotNull('estimated_duration_hours')
            ->whereIn('driver_status', ['arrived_destination', 'done'])
            ->get()
            ->each(function (Order $order) use ($now) {
                $expectedEnd = Carbon::parse($order->scheduled_at)
                    ->addHours($order->estimated_duration_hours);

                if ($now->greaterThan($expectedEnd)) {
                    DB::transaction(function () use ($order) {
                        $order->update([
                            'status'            => 'completed',
                            'completed_at'      => now(),
                            'auto_completed_at' => now(),
                            'completion_method' => 'auto_time',
                        ]);

                        OrderStatusLog::create([
                            'order_id'    => $order->id,
                            'user_id'     => null,
                            'from_status' => 'in_progress',
                            'to_status'   => 'completed',
                            'notes'       => "Auto-completed: jam eksekusi sudah terlewat ({$order->estimated_duration_hours} jam).",
                        ]);

                        // AI generate duka text (background)
                        dispatch(new \App\Jobs\GenerateDukaText($order));

                        // Consumer notif
                        if ($order->pic_user_id) {
                            NotificationService::send($order->pic_user_id, 'HIGH',
                                'Layanan Selesai',
                                "Layanan pemakaman untuk order {$order->order_number} telah selesai. Silakan lakukan pembayaran melalui aplikasi.",
                                ['order_id' => $order->id, 'action' => 'upload_payment_proof']
                            );
                        }

                        // Finance notif
                        NotificationService::sendToRole('finance', 'ALARM',
                            "Cek Status Payment — {$order->order_number}",
                            "Order selesai. Tunggu bukti payment dari konsumen atau hubungi penanggung jawab.",
                            ['order_id' => $order->id]
                        );

                        // Owner notif
                        NotificationService::sendToRole('owner', 'NORMAL',
                            "Order {$order->order_number} Selesai",
                            "Auto-completed. Estimasi durasi {$order->estimated_duration_hours} jam sudah terlewat.",
                            ['order_id' => $order->id]
                        );
                    });

                    $this->info("Auto-completed: {$order->order_number}");
                }
            });

        // Cek order yang melebihi toleransi (+ 2 jam) tapi driver belum tiba
        Order::where('status', 'in_progress')
            ->whereNotNull('scheduled_at')
            ->whereNotNull('estimated_duration_hours')
            ->whereNotIn('driver_status', ['arrived_destination', 'done'])
            ->get()
            ->each(function (Order $order) use ($now) {
                $tolerance = Carbon::parse($order->scheduled_at)
                    ->addHours($order->estimated_duration_hours + 2);

                if ($now->greaterThan($tolerance)) {
                    NotificationService::sendToRole('owner', 'ALARM',
                        "⚠ Order Melebihi Estimasi — {$order->order_number}",
                        "Driver belum tiba di tujuan. Sudah lewat " . ($order->estimated_duration_hours + 2) . " jam dari jadwal.",
                        ['order_id' => $order->id]
                    );
                    $this->warn("Overtime alert: {$order->order_number}");
                }
            });
    }
}
