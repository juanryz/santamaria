<?php

namespace App\Jobs;

use App\Models\Order;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

use App\Models\Vehicle;
use App\Models\OrderStatusLog;

class AssignDriverToOrder implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(private Order $order) {}

    public function handle(): void
    {
        // 1. Temukan Driver
        $driver = User::where('role', 'driver')
            ->whereDoesntHave('assignedOrders', function ($q) {
                $q->whereIn('status', ['confirmed', 'in_progress', 'approved']);
            })
            ->first();

        // 2. Temukan Armada (Mobil)
        $scheduledTime = new \DateTime($this->order->scheduled_at);
        $startTime = (clone $scheduledTime)->modify('-3 hours')->format('Y-m-d H:i:s');
        $endTime = (clone $scheduledTime)->modify('+3 hours')->format('Y-m-d H:i:s');

        $assignedVehicleIds = Order::whereBetween('scheduled_at', [$startTime, $endTime])
            ->whereIn('status', ['approved', 'confirmed', 'in_progress'])
            ->whereNotNull('vehicle_id')
            ->pluck('vehicle_id');

        // Prioritas 1: Armada yang khusus map dengan paket order ini
        $vehicle = Vehicle::where('is_active', true)
            ->where('type', 'jenazah')
            ->whereNotIn('id', $assignedVehicleIds)
            ->where('package_id', $this->order->package_id)
            ->first();

        // Prioritas 2: Armada jenazah yang sifatnya publik/umum (tanpa package_id)
        if (!$vehicle) {
            $vehicle = Vehicle::where('is_active', true)
                ->where('type', 'jenazah')
                ->whereNotIn('id', $assignedVehicleIds)
                ->whereNull('package_id')
                ->first();
        }

        // Prioritas 3: Armada jenazah apa saja (lintas paket jika kosong)
        if (!$vehicle) {
            $vehicle = Vehicle::where('is_active', true)
                ->where('type', 'jenazah')
                ->whereNotIn('id', $assignedVehicleIds)
                ->first();
        }

        // Update Order
        $updates = ['status' => 'approved', 'approved_at' => now()];

        if ($driver) {
            $updates['driver_id'] = $driver->id;
        }

        if ($vehicle) {
            $updates['vehicle_id'] = $vehicle->id;
        }

        $this->order->update($updates);

        OrderStatusLog::create([
            'order_id' => $this->order->id,
            'user_id' => $this->order->so_user_id ?? 1, // System fallback
            'from_status' => 'confirmed',
            'to_status' => 'approved',
            'notes' => 'AI berhasil memproses armada (Vehicle: ' . ($vehicle ? $vehicle->plate_number : 'KOSONG') . ').'
        ]);

        // Kondisi Kekosongan Armada
        if (!$vehicle) {
            NotificationService::sendToRole('finance', 'ALARM',
                'Armada Habis - Pengajuan Eksternal',
                "Seluruh armada paket habis! Order {$this->order->order_number} memerlukan supplier/eksternal. Segera setujui pengadaan mobil luar.",
                ['order_id' => $this->order->id]
            );
        }

        if (!$driver) {
            NotificationService::sendToRole('admin', 'ALARM',
                'Kekurangan Driver',
                "Order {$this->order->order_number} tidak dapat di-assign driver otomatis.",
                ['order_id' => $this->order->id]
            );
        }

        if ($driver && $vehicle) {
            NotificationService::send($driver->id, 'ALARM',
                "Kamu Ditugaskan ke Order {$this->order->order_number}",
                "Mobil: {$vehicle->plate_number}. Penjemputan: {$this->order->pickup_address}. Tujuan: {$this->order->destination_address} Jadwal: " . \Carbon\Carbon::parse($this->order->scheduled_at)->format('d M Y H:i'),
                ['order_id' => $this->order->id, 'action' => 'view_order']
            );
        }
    }
}
