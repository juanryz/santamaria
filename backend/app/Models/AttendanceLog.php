<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AttendanceLog extends Model
{
    use HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'user_id', 'action', 'latitude', 'longitude',
        'distance_meters', 'is_within_radius', 'is_mock',
        'device_info', 'details',
    ];

    protected $casts = [
        'is_within_radius' => 'boolean',
        'is_mock' => 'boolean',
    ];

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
}
