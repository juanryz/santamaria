<?php

namespace App\Events;

use App\Models\PurchaseOrder;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class PurchaseOrderCreated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public readonly PurchaseOrder $purchaseOrder)
    {
    }

    /**
     * Broadcast on the public 'supplier-catalog' channel so all logged-in
     * supplier clients receive the event without per-user auth.
     * Channel name matches QA doc section 4.1 / 8.1.
     */
    public function broadcastOn(): array
    {
        return [
            new Channel('supplier-catalog'),
        ];
    }

    public function broadcastAs(): string
    {
        return 'ProcurementRequestPublished';
    }

    public function broadcastWith(): array
    {
        return [
            'id'             => $this->purchaseOrder->id,
            'item_name'      => $this->purchaseOrder->item_name,
            'quantity'       => $this->purchaseOrder->quantity,
            'unit'           => $this->purchaseOrder->unit,
            'proposed_price' => $this->purchaseOrder->proposed_price,
            'status'         => $this->purchaseOrder->status,
        ];
    }
}
