<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class StockTransaction extends Model
{
    use \App\Traits\Uuids;

    public $timestamps = false;

    protected $fillable = [
        'stock_item_id',
        'order_id',
        'type',
        'quantity',
        'notes',
        'user_id',
        'created_at',
    ];

    protected $casts = [
        'created_at' => 'datetime',
    ];

    public function stockItem()
    {
        return $this->belongsTo(StockItem::class);
    }

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
