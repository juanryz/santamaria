<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CoffinOrderStage extends Model
{
    use HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'coffin_order_id', 'stage_master_id', 'stage_number', 'stage_name',
        'is_completed', 'completed_at', 'completed_by_name', 'notes',
    ];

    protected $casts = [
        'is_completed' => 'boolean',
        'completed_at' => 'datetime',
    ];

    public function coffinOrder(): BelongsTo
    {
        return $this->belongsTo(CoffinOrder::class);
    }

    public function stageMaster(): BelongsTo
    {
        return $this->belongsTo(CoffinStageMaster::class, 'stage_master_id');
    }
}
