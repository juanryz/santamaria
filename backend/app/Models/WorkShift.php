<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class WorkShift extends Model
{
    use HasUuids;

    protected $fillable = [
        'shift_name', 'start_time', 'end_time',
        'late_tolerance_minutes', 'early_leave_tolerance_minutes', 'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];
}
