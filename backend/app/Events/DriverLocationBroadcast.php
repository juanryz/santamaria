<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class DriverLocationBroadcast implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public string $orderId,
        public string $driverId,
        public float $latitude,
        public float $longitude,
        public ?float $speed,
        public ?float $heading,
    ) {}

    public function broadcastOn(): array
    {
        return [new Channel("order.{$this->orderId}")];
    }

    public function broadcastAs(): string
    {
        return 'driver.location';
    }
}
