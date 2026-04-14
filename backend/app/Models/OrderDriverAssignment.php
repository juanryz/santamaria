<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderDriverAssignment extends Model
{
    use HasUuids;

    protected $fillable = [
        'order_id', 'leg_master_id', 'driver_id', 'vehicle_id', 'leg_sequence',
        'origin_label', 'destination_label',
        'origin_lat', 'origin_lng', 'destination_lat', 'destination_lng',
        'status', 'assigned_at', 'departed_at', 'arrived_at', 'completed_at',
        'proof_photo_path', 'notes', 'km_start', 'km_end',
    ];

    protected $casts = [
        'assigned_at' => 'datetime',
        'departed_at' => 'datetime',
        'arrived_at' => 'datetime',
        'completed_at' => 'datetime',
        'origin_lat' => 'decimal:8',
        'origin_lng' => 'decimal:8',
        'destination_lat' => 'decimal:8',
        'destination_lng' => 'decimal:8',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function legMaster(): BelongsTo
    {
        return $this->belongsTo(TripLegMaster::class, 'leg_master_id');
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    /** Calculate KM driven */
    public function getKmDrivenAttribute(): ?float
    {
        if ($this->km_start && $this->km_end) {
            return $this->km_end - $this->km_start;
        }
        return null;
    }
}
