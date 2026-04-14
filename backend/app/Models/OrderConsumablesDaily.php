<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class OrderConsumablesDaily extends Model
{
    use HasUuids;

    protected $table = 'order_consumables_daily';

    protected $fillable = [
        'order_id', 'consumable_date', 'shift', 'is_retur',
        'input_by', 'tukang_jaga_1_name', 'tukang_jaga_2_name', 'notes',
    ];

    protected $casts = [
        'consumable_date' => 'date',
        'is_retur' => 'boolean',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function inputByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'input_by');
    }

    public function lines(): HasMany
    {
        return $this->hasMany(OrderConsumableLine::class, 'consumable_daily_id');
    }
}
