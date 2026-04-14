<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class AttendanceUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public string $orderId,
        public string $userId,
        public string $status,
        public string $role,
    ) {}

    public function broadcastOn(): array
    {
        return [new Channel("order.{$this->orderId}")];
    }

    public function broadcastAs(): string
    {
        return 'attendance.updated';
    }
}
