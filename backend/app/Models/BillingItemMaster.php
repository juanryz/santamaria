<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class BillingItemMaster extends Model
{
    use HasUuids;

    protected $table = 'billing_item_master';

    protected $fillable = [
        'item_code', 'item_name', 'category', 'default_unit',
        'default_unit_price', 'sort_order', 'is_active',
    ];

    protected $casts = [
        'default_unit_price' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderBillingItem::class, 'billing_master_id');
    }
}
