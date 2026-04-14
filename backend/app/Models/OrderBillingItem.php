<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderBillingItem extends Model
{
    use HasUuids;

    protected $fillable = [
        'order_id', 'billing_master_id', 'qty', 'unit', 'unit_price',
        'total_price', 'source', 'tambahan', 'kembali', 'notes',
    ];

    protected $casts = [
        'qty' => 'decimal:2',
        'unit_price' => 'decimal:2',
        'total_price' => 'decimal:2',
        'tambahan' => 'decimal:2',
        'kembali' => 'decimal:2',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function billingMaster(): BelongsTo
    {
        return $this->belongsTo(BillingItemMaster::class, 'billing_master_id');
    }
}
