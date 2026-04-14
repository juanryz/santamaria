<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class CoffinOrderUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public string $coffinOrderId,
        public string $status,
        public string $action,
    ) {}

    public function broadcastOn(): array
    {
        return [new Channel('gudang.coffin')];
    }

    public function broadcastAs(): string
    {
        return 'coffin.updated';
    }
}
