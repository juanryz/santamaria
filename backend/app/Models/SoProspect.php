<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class SoProspect extends Model
{
    use HasUuids;

    protected $fillable = [
        'so_user_id',
        'name',
        'phone',
        'address',
        'source',
        'status',
        'notes',
        'follow_up_date',
        'converted_order_id',
    ];

    protected $casts = [
        'follow_up_date' => 'date',
    ];

    public function soUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'so_user_id');
    }

    public function convertedOrder(): BelongsTo
    {
        return $this->belongsTo(Order::class, 'converted_order_id');
    }

    public function visitLogs(): HasMany
    {
        return $this->hasMany(SoVisitLog::class, 'prospect_id');
    }
}
