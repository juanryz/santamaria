<?php

namespace App\Events;

use App\Models\DriverLocation;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class DriverLocationUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $location;

    public function __construct(DriverLocation $location)
    {
        $this->location = $location;
    }

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('orders.' . $this->location->order_id),
        ];
    }

    public function broadcastAs()
    {
        return 'driver.location';
    }
}
