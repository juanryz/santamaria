<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class EquipmentMaster extends Model
{
    use HasUuids;

    protected $table = 'equipment_master';

    protected $fillable = [
        'category', 'sub_category', 'item_name', 'item_code',
        'default_qty', 'unit', 'is_active', 'notes',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderEquipmentItem::class, 'equipment_item_id');
    }
}
