<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class KpiPeriod extends Model
{
    use HasUuids;

    protected $fillable = [
        'period_name', 'period_type', 'start_date', 'end_date',
        'status', 'closed_by', 'closed_at',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'closed_at' => 'datetime',
    ];

    public function scores(): HasMany
    {
        return $this->hasMany(KpiScore::class, 'period_id');
    }

    public function summaries(): HasMany
    {
        return $this->hasMany(KpiUserSummary::class, 'period_id');
    }

    public function closedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'closed_by');
    }
}
