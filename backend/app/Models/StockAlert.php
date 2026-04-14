<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StockAlert extends Model
{
    use HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'stock_item_id', 'order_id', 'alert_type',
        'current_quantity', 'minimum_quantity', 'message',
        'is_resolved', 'resolved_by', 'resolved_at',
    ];

    protected $casts = [
        'current_quantity' => 'decimal:2',
        'minimum_quantity' => 'decimal:2',
        'is_resolved' => 'boolean',
        'resolved_at' => 'datetime',
    ];

    public function stockItem(): BelongsTo
    {
        return $this->belongsTo(StockItem::class);
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function resolvedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'resolved_by');
    }
}
