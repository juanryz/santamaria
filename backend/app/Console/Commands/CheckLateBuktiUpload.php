<?php

namespace App\Console\Commands;

use App\Models\HrdViolation;
use App\Models\Order;
use App\Models\OrderBuktiLapangan;
use App\Models\SystemThreshold;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class CheckLateBuktiUpload extends Command
{
    protected $signature   = 'hrd:check-late-bukti-upload';
    protected $description = 'Detect drivers/vendors who have not uploaded proof photos after order completion.';

    public function handle(): void
    {
        $deadlineHours = SystemThreshold::getValue('bukti_upload_deadline_hours', 2);

        // Cari order completed dalam X jam terakhir
        Order::where('status', 'completed')
            ->whereNotNull('completed_at')
            ->where('completed_at', '>=', now()->subHours($deadlineHours + 1))
            ->get()
            ->each(function (Order $order) use ($deadlineHours) {
                $hoursAfter = Carbon::parse($order->completed_at)->diffInHours(now());

                if ($hoursAfter < $deadlineHours) {
                    return;
                }

                // Cek bukti driver
                $driverBukti = OrderBuktiLapangan::where('order_id', $order->id)
                    ->where('role', 'driver')
                    ->count();

                if ($driverBukti === 0 && $order->driver_id) {
                    $this->createViolation($order, $order->driver_id, 'driver', $hoursAfter, $deadlineHours);
                }

                // Cek bukti dekor
                if ($order->dekor_status === 'done') {
                    $dekorBukti = OrderBuktiLapangan::where('order_id', $order->id)
                        ->where('role', 'dekor')
                        ->count();

                    if ($dekorBukti === 0) {
                        $dekorUser = \App\Models\VendorPerformance::where('order_id', $order->id)
                            ->where('vendor_role', 'dekor')
                            ->value('vendor_user_id');
                        if ($dekorUser) {
                            $this->createViolation($order, $dekorUser, 'dekor', $hoursAfter, $deadlineHours);
                        }
                    }
                }
            });

        $this->info('Late bukti upload check selesai.');
    }

    private function createViolation(Order $order, string $userId, string $role, float $hoursAfter, float $deadline): void
    {
        $exists = HrdViolation::where('violated_by', $userId)
            ->where('order_id', $order->id)
            ->where('violation_type', 'late_bukti_upload')
            ->exists();

        if ($exists) {
            return;
        }

        $user = \App\Models\User::find($userId);

        $violation = HrdViolation::create([
            'violated_by'     => $userId,
            'order_id'        => $order->id,
            'violation_type'  => 'late_bukti_upload',
            'description'     => "{$user->name} ({$role}) belum upload bukti foto untuk order {$order->order_number}. Sudah {$hoursAfter} jam (maks {$deadline} jam).",
            'threshold_value' => $deadline,
            'actual_value'    => $hoursAfter,
            'severity'        => 'low',
            'status'          => 'new',
        ]);

        NotificationService::sendHrdViolationAlert($violation);
        $this->warn("Late bukti upload: {$user->name} order {$order->order_number}");
    }
}
