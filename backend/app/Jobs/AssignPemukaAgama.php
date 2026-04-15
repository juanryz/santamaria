<?php

namespace App\Jobs;

use App\Enums\UserRole;
use App\Models\Order;
use App\Models\User;
use App\Models\PemukaAgamaAssignment;
use App\Services\NotificationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class AssignPemukaAgama implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(private Order $order) {}

    public function handle(): void
    {
        // AI matching: pilih pemuka agama sesuai agama almarhum yang tersedia
        $candidate = User::where('role', UserRole::PEMUKA_AGAMA->value)
            ->whereNotNull('device_fcm_token')
            ->first();

        if (!$candidate) {
            return;
        }

        PemukaAgamaAssignment::updateOrCreate(
            ['order_id' => $this->order->id],
            [
                'pemuka_agama_user_id' => $candidate->id,
                'status'               => 'offered',
                'offered_at'           => now(),
                'timeout_at'           => now()->addMinutes(30),
            ]
        );

        $this->order->update([
            'pemuka_agama_status'  => 'finding',
            'pemuka_agama_user_id' => $candidate->id,
        ]);

        NotificationService::send($candidate->id, 'ALARM',
            "Order {$this->order->order_number} — Konfirmasi Kehadiran!",
            "Jadwal: " . \Carbon\Carbon::parse($this->order->scheduled_at)->format('d M Y H:i') . ". Agama: {$this->order->deceased_religion}.",
            ['order_id' => $this->order->id, 'action' => 'confirm_assignment']
        );
    }
}
