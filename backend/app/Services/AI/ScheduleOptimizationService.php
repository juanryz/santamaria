<?php

namespace App\Services\AI;

use App\Models\Order;
use App\Models\DriverSession;
use App\Models\Vehicle;
use App\Models\User;
use App\Enums\OrderStatus;
use App\Enums\UserRole;
use Carbon\Carbon;

class ScheduleOptimizationService extends BaseAiService
{
    private const SYSTEM_PROMPT = <<<PROMPT
Kamu adalah scheduler optimizer untuk Santa Maria Funeral Organizer.
Berdasarkan data order aktif, ketersediaan driver, dan kendaraan, rekomendasikan jadwal optimal.
Pertimbangkan: lokasi (jarak), waktu perjalanan, beban kerja driver, dan kondisi kendaraan.

Kembalikan HANYA JSON valid:
{
  "recommended_schedule": {
    "driver_id": "uuid",
    "driver_name": "nama",
    "vehicle_id": "uuid",
    "vehicle_model": "nama kendaraan",
    "estimated_departure": "ISO timestamp",
    "estimated_arrival": "ISO timestamp",
    "route_notes": "catatan rute"
  },
  "conflicts": ["konflik jadwal jika ada"],
  "optimization_notes": "catatan optimasi",
  "alternative": {
    "driver_id": "uuid alternatif",
    "driver_name": "nama",
    "reason": "alasan alternatif"
  }
}
PROMPT;

    /**
     * Optimize scheduling for a given order.
     */
    public function optimizeSchedule(Order $order): array
    {
        // Get active orders on the same date
        $scheduledDate = $order->scheduled_at?->toDateString() ?? now()->toDateString();

        $activeOrders = Order::whereIn('status', OrderStatus::activeStatuses())
            ->whereDate('scheduled_at', $scheduledDate)
            ->where('id', '!=', $order->id)
            ->with(['driver', 'vehicle'])
            ->get();

        // Available drivers
        $drivers = User::where('role', UserRole::DRIVER->value)
            ->where('is_active', true)
            ->get()
            ->map(function ($d) use ($activeOrders) {
                $assignedCount = $activeOrders->where('driver_id', $d->id)->count();
                $onDuty = DriverSession::where('driver_id', $d->id)->whereNull('ended_at')->exists();
                return [
                    'id' => $d->id,
                    'name' => $d->name,
                    'assigned_today' => $assignedCount,
                    'on_duty' => $onDuty,
                    'available' => $assignedCount < 3, // max 3 orders per driver per day
                ];
            });

        // Available vehicles
        $vehicles = Vehicle::where('is_active', true)
            ->get()
            ->map(function ($v) use ($activeOrders) {
                $inUse = $activeOrders->where('vehicle_id', $v->id)->isNotEmpty();
                return [
                    'id' => $v->id,
                    'model' => $v->model,
                    'plate' => $v->plate_number,
                    'in_use' => $inUse,
                    'available' => !$inUse,
                ];
            });

        $userPrompt = <<<PROMPT
Order: {$order->order_number}
Jadwal: {$order->scheduled_at}
Penjemputan: {$order->pickup_address}
Tujuan: {$order->destination_address}

Order aktif hari yang sama: {$activeOrders->count()}

Driver tersedia:
PROMPT;

        foreach ($drivers as $d) {
            $status = $d['available'] ? 'TERSEDIA' : "SIBUK ({$d['assigned_today']} order)";
            $userPrompt .= "\n- {$d['name']} (ID: {$d['id']}): {$status}";
        }

        $userPrompt .= "\n\nKendaraan:";
        foreach ($vehicles as $v) {
            $status = $v['available'] ? 'TERSEDIA' : 'SEDANG DIPAKAI';
            $userPrompt .= "\n- {$v['model']} ({$v['plate']}): {$status}";
        }

        $messages = [
            ['role' => 'system', 'content' => self::SYSTEM_PROMPT],
            ['role' => 'user', 'content' => $userPrompt],
        ];

        $result = $this->callOpenAI('schedule_optimization', $messages, [], $order->id);

        if ($result['success']) {
            $content = preg_replace('/^```json\s*|\s*```$/', '', trim($result['content']));
            $parsed = json_decode($content, true);
            return ['success' => true, 'data' => $parsed ?? ['raw' => $content]];
        }

        // Fallback: pick first available driver + vehicle
        $availableDriver = collect($drivers)->firstWhere('available', true);
        $availableVehicle = collect($vehicles)->firstWhere('available', true);

        return [
            'success' => true,
            'data' => [
                'recommended_schedule' => [
                    'driver_id' => $availableDriver['id'] ?? null,
                    'driver_name' => $availableDriver['name'] ?? 'Tidak ada',
                    'vehicle_id' => $availableVehicle['id'] ?? null,
                    'vehicle_model' => $availableVehicle['model'] ?? 'Tidak ada',
                ],
                'conflicts' => [],
                'optimization_notes' => 'Fallback: driver & kendaraan pertama yang tersedia',
            ],
            'source' => 'fallback',
        ];
    }
}
