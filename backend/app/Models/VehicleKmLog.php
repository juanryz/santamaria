<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VehicleKmLog extends Model
{
    use HasUuids;

    protected $fillable = [
        'vehicle_id', 'driver_id', 'log_type', 'km_reading',
        'photo_path', 'order_id', 'notes',
    ];

    public function vehicle(): BelongsTo { return $this->belongsTo(Vehicle::class); }
    public function driver(): BelongsTo { return $this->belongsTo(User::class, 'driver_id'); }
}
