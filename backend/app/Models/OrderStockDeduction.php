<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderStockDeduction extends Model
{
    use HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'order_id', 'stock_item_id', 'package_item_id',
        'deducted_quantity', 'stock_before', 'stock_after',
        'is_sufficient', 'deducted_by', 'deducted_at', 'notes',
    ];

    protected $casts = [
        'deducted_quantity' => 'decimal:2',
        'stock_before' => 'decimal:2',
        'stock_after' => 'decimal:2',
        'is_sufficient' => 'boolean',
        'deducted_at' => 'datetime',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function stockItem(): BelongsTo
    {
        return $this->belongsTo(StockItem::class);
    }

    public function packageItem(): BelongsTo
    {
        return $this->belongsTo(PackageItem::class);
    }

    public function deductedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'deducted_by');
    }
}
