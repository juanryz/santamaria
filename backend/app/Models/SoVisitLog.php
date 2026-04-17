<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SoVisitLog extends Model
{
    use HasUuids;

    protected $fillable = [
        'so_user_id',
        'prospect_id',
        'order_id',
        'location',
        'purpose',
        'notes',
        'visit_date',
        'photo_evidence_id',
    ];

    protected $casts = [
        'visit_date' => 'date',
    ];

    public function soUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'so_user_id');
    }

    public function prospect(): BelongsTo
    {
        return $this->belongsTo(SoProspect::class, 'prospect_id');
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function photoEvidence(): BelongsTo
    {
        return $this->belongsTo(PhotoEvidence::class, 'photo_evidence_id');
    }
}
