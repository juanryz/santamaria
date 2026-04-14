<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderEquipmentItem extends Model
{
    use HasUuids;

    protected $fillable = [
        'order_id', 'equipment_loan_id', 'equipment_item_id', 'category',
        'item_code', 'item_description', 'qty_sent', 'qty_received',
        'qty_returned', 'status', 'sent_by', 'sent_at',
        'received_by_family_name', 'received_by_family_at', 'received_by_pic_id',
        'returned_by_family_name', 'returned_at', 'accepted_return_by', 'notes',
    ];

    protected $casts = [
        'sent_at' => 'datetime',
        'received_by_family_at' => 'datetime',
        'returned_at' => 'datetime',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function equipmentLoan(): BelongsTo
    {
        return $this->belongsTo(EquipmentLoan::class);
    }

    public function equipmentMaster(): BelongsTo
    {
        return $this->belongsTo(EquipmentMaster::class, 'equipment_item_id');
    }

    public function sentByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sent_by');
    }
}
