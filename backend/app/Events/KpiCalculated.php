<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class KpiCalculated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public string $periodId,
        public string $periodName,
    ) {}

    public function broadcastOn(): array
    {
        return [new Channel('kpi')];
    }

    public function broadcastAs(): string
    {
        return 'kpi.calculated';
    }
}
