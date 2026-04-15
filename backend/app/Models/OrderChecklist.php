<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderChecklist extends Model
{
    use \App\Traits\Uuids;

    protected $fillable = [
        'order_id',
        'stock_item_id',
        'item_name',
        'quantity',
        'unit',
        'notes',
        'is_checked',
        'checked_by',
        'checked_at',
        // columns from original migration (retained for compat)
        'religion',
        'item_category',
        'target_role',
        'provider_role',
    ];

    protected $casts = [
        'is_checked'  => 'boolean',
        'checked_at'  => 'datetime',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function stockItem()
    {
        return $this->belongsTo(StockItem::class);
    }

    public function checkedBy()
    {
        return $this->belongsTo(User::class, 'checked_by');
    }
}
