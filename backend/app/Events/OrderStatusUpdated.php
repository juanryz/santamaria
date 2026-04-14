<?php

namespace App\Events;

use App\Models\Order;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class OrderStatusUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $order;
    public $status;

    public function __construct(Order $order)
    {
        $this->order = $order;
        $this->status = $order->status;
    }

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('orders.' . $this->order->id),
            new PrivateChannel('admin.orders'),
        ];
    }

    public function broadcastAs()
    {
        return 'order.updated';
    }
}
