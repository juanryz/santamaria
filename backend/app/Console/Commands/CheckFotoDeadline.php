<?php

namespace App\Console\Commands;

use App\Models\Order;
use App\Models\OrderGalleryLink;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class CheckFotoDeadline extends Command
{
    protected $signature = 'foto:check-deadline';
    protected $description = 'Check completed orders missing gallery links after 3 hours';

    public function handle(): int
    {
        $orders = Order::where('status', 'completed')
            ->where('completed_at', '<', now()->subHours(3))
            ->whereDoesntHave('galleryLinks')
            ->get();

        foreach ($orders as $order) {
            Log::warning('Order missing gallery links past deadline', [
                'order_id' => $order->id,
                'order_number' => $order->order_number,
                'completed_at' => $order->completed_at,
            ]);
        }

        $this->info("Found {$orders->count()} orders missing gallery links.");

        return self::SUCCESS;
    }
}
