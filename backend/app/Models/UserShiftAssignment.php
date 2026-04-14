<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserShiftAssignment extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id', 'shift_id', 'location_id', 'effective_from', 'effective_until', 'is_active',
    ];

    protected $casts = [
        'effective_from' => 'date',
        'effective_until' => 'date',
        'is_active' => 'boolean',
    ];

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function shift(): BelongsTo { return $this->belongsTo(WorkShift::class, 'shift_id'); }
    public function location(): BelongsTo { return $this->belongsTo(AttendanceLocation::class, 'location_id'); }
}
