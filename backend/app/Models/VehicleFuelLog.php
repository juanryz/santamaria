<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VehicleFuelLog extends Model
{
    use HasUuids;

    protected $fillable = [
        'vehicle_id', 'driver_id', 'liters', 'price_per_liter', 'total_cost',
        'fuel_type', 'km_reading', 'receipt_photo_path', 'speedometer_photo_path',
        'station_name', 'validation_status', 'validated_by', 'notes',
    ];

    protected $casts = [
        'liters' => 'decimal:2',
        'price_per_liter' => 'decimal:2',
        'total_cost' => 'decimal:2',
    ];

    public function vehicle(): BelongsTo { return $this->belongsTo(Vehicle::class); }
    public function driver(): BelongsTo { return $this->belongsTo(User::class, 'driver_id'); }
}
