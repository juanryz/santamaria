<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CoffinStageMaster extends Model
{
    use HasUuids;

    protected $table = 'coffin_stage_master';

    protected $fillable = [
        'finishing_type', 'stage_number', 'stage_name', 'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function orderStages(): HasMany
    {
        return $this->hasMany(CoffinOrderStage::class, 'stage_master_id');
    }
}
