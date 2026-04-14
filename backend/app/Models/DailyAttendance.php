<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DailyAttendance extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id', 'attendance_date', 'shift_id', 'location_id', 'status',
        'clock_in_at', 'clock_in_lat', 'clock_in_lng', 'clock_in_distance_meters', 'clock_in_selfie_path',
        'clock_out_at', 'clock_out_lat', 'clock_out_lng', 'clock_out_distance_meters', 'clock_out_selfie_path',
        'work_hours', 'is_mock_detected', 'mock_details',
        'is_overridden', 'overridden_by', 'override_reason', 'notes',
    ];

    protected $casts = [
        'attendance_date' => 'date',
        'clock_in_at' => 'datetime',
        'clock_out_at' => 'datetime',
        'is_mock_detected' => 'boolean',
        'is_overridden' => 'boolean',
        'work_hours' => 'decimal:2',
    ];

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function shift(): BelongsTo { return $this->belongsTo(WorkShift::class, 'shift_id'); }
    public function location(): BelongsTo { return $this->belongsTo(AttendanceLocation::class, 'location_id'); }
}
