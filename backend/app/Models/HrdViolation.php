<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HrdViolation extends Model
{
    protected $fillable = [
        'violated_by',
        'order_id',
        'violation_type',
        'description',
        'threshold_value',
        'actual_value',
        'severity',
        'hrd_notes',
        'status',
        'acknowledged_by',
        'acknowledged_at',
        'resolved_by',
        'resolved_at',
    ];

    protected $casts = [
        'threshold_value'  => 'decimal:2',
        'actual_value'     => 'decimal:2',
        'acknowledged_at'  => 'datetime',
        'resolved_at'      => 'datetime',
    ];

    public function violatedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'violated_by');
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function acknowledgedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'acknowledged_by');
    }

    public function resolvedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'resolved_by');
    }
}
