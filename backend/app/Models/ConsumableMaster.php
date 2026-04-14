<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ConsumableMaster extends Model
{
    use HasUuids;

    protected $table = 'consumable_master';

    protected $fillable = [
        'item_code', 'item_name', 'unit', 'category', 'sort_order', 'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function lines(): HasMany
    {
        return $this->hasMany(OrderConsumableLine::class, 'consumable_master_id');
    }
}
