<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class KpiUserSummary extends Model
{
    use HasUuids;

    protected $table = 'kpi_user_summary';

    protected $fillable = [
        'period_id', 'user_id', 'total_score', 'grade',
        'rank_in_role', 'total_in_role', 'prev_total_score',
        'trend', 'calculated_at',
    ];

    protected $casts = [
        'total_score' => 'decimal:2',
        'prev_total_score' => 'decimal:2',
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
}
