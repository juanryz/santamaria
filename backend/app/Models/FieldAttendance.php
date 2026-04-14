<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FieldAttendance extends Model
{
    use HasUuids;

    protected $fillable = [
        'order_id', 'user_id', 'role', 'attendance_date', 'kegiatan',
        'scheduled_jam', 'arrived_at', 'departed_at', 'status',
        'pic_confirmed', 'pic_confirmed_by', 'pic_confirmed_at',
        'pic_signature_path', 'notes',
    ];

    protected $casts = [
        'attendance_date' => 'date',
        'arrived_at' => 'datetime',
        'departed_at' => 'datetime',
        'pic_confirmed' => 'boolean',
        'pic_confirmed_at' => 'datetime',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function confirmedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'pic_confirmed_by');
    }
}
