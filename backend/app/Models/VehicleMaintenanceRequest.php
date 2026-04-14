<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VehicleMaintenanceRequest extends Model
{
    use HasUuids;

    protected $fillable = [
        'vehicle_id', 'reported_by', 'category', 'priority', 'description',
        'photo_path', 'status', 'assigned_to',
        'acknowledged_at', 'started_at', 'completed_at',
        'cost', 'resolution_notes',
    ];

    protected $casts = [
        'acknowledged_at' => 'datetime',
        'started_at' => 'datetime',
        'completed_at' => 'datetime',
        'cost' => 'decimal:2',
    ];

    public function vehicle(): BelongsTo { return $this->belongsTo(Vehicle::class); }
    public function reporter(): BelongsTo { return $this->belongsTo(User::class, 'reported_by'); }
}
