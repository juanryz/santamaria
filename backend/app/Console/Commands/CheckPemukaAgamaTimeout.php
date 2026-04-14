<?php

namespace App\Console\Commands;

use App\Enums\UserRole;
use App\Models\PemukaAgamaAssignment;
use App\Models\Order;
use App\Services\NotificationService;
use Illuminate\Console\Command;

class CheckPemukaAgamaTimeout extends Command
{
    protected $signature = 'pemuka-agama:check-timeout';
    protected $description = 'Check for timed out religious leader assignments and notify next';

    public function handle()
    {
        $expired = PemukaAgamaAssignment::where('response', 'pending')
            ->where('expiry_at', '<', now())
            ->get();

        foreach ($expired as $assignment) {
            $assignment->update(['response' => 'expired']);
            
            // Logic to move to next candidate would go here
            // For now, alert admin
            $order = $assignment->order;
            NotificationService::sendToRole(UserRole::ADMIN->value, 'HIGH', 'Pemuka Agama Timeout', "Assignment untuk {$order->order_number} telah kedaluwarsa.");
        }
        
        $this->info('Checked ' . $expired->count() . ' assignments.');
    }
}
