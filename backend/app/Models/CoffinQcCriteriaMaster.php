<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CoffinQcCriteriaMaster extends Model
{
    use HasUuids;

    protected $table = 'coffin_qc_criteria_master';

    protected $fillable = [
        'criteria_code', 'criteria_name', 'finishing_type', 'sort_order', 'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function results(): HasMany
    {
        return $this->hasMany(CoffinQcResult::class, 'criteria_master_id');
    }
}
