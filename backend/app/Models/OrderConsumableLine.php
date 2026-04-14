<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderConsumableLine extends Model
{
    use HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'consumable_daily_id', 'consumable_master_id', 'qty', 'notes',
    ];

    public function daily(): BelongsTo
    {
        return $this->belongsTo(OrderConsumablesDaily::class, 'consumable_daily_id');
    }

    public function master(): BelongsTo
    {
        return $this->belongsTo(ConsumableMaster::class, 'consumable_master_id');
    }
}
