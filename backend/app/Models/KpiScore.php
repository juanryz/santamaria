<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class KpiScore extends Model
{
    use HasUuids;

    protected $fillable = [
        'period_id', 'user_id', 'metric_id',
        'actual_value', 'target_value', 'score', 'weighted_score', 'weight',
        'calculation_detail', 'calculated_at',
    ];

    protected $casts = [
        'actual_value' => 'decimal:2',
        'target_value' => 'decimal:2',
        'score' => 'decimal:2',
        'weighted_score' => 'decimal:2',
        'weight' => 'decimal:2',
        'calculation_detail' => 'array',
        'calculated_at' => 'datetime',
    ];

    public function period(): BelongsTo
    {
        return $this->belongsTo(KpiPeriod::class, 'period_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function metric(): BelongsTo
    {
        return $this->belongsTo(KpiMetricMaster::class, 'metric_id');
    }
}
