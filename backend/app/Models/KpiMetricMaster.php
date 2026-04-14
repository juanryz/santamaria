<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class KpiMetricMaster extends Model
{
    use HasUuids;

    protected $table = 'kpi_metric_master';

    protected $fillable = [
        'metric_code', 'metric_name', 'description', 'applicable_role',
        'data_source', 'calculation_type', 'calculation_query', 'unit',
        'target_value', 'target_direction', 'weight', 'sort_order', 'is_active',
    ];

    protected $casts = [
        'target_value' => 'decimal:2',
        'weight' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    public function scores(): HasMany
    {
        return $this->hasMany(KpiScore::class, 'metric_id');
    }
}
