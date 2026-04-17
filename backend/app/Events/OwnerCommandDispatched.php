<?php

namespace App\Events;

use App\Models\OwnerCommand;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * v1.36 — Broadcast perintah owner ke channel karyawan spesifik.
 * Channel: user.{userId} — setiap karyawan subscribe ke channel pribadinya.
 */
class OwnerCommandDispatched implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public readonly OwnerCommand $command,
        public readonly string $targetUserId,
    ) {}

    public function broadcastOn(): array
    {
        return [new Channel("user.{$this->targetUserId}")];
    }

    public function broadcastAs(): string
    {
        return 'owner.command';
    }

    public function broadcastWith(): array
    {
        return [
            'command_id' => $this->command->id,
            'title'      => $this->command->title,
            'message'    => $this->command->message,
            'priority'   => $this->command->priority,
            'owner_name' => $this->command->owner->name ?? 'Owner',
            'sent_at'    => $this->command->created_at->toIso8601String(),
        ];
    }
}
