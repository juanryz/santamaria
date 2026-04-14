<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class VehicleInspection extends Model
{
    use HasUuids;

    protected $fillable = [
        'vehicle_id', 'driver_id', 'inspection_type', 'km_reading',
        'total_items', 'passed_items', 'failed_items', 'overall_passed', 'notes',
    ];

    protected $casts = ['overall_passed' => 'boolean'];

    public function vehicle(): BelongsTo { return $this->belongsTo(Vehicle::class); }
    public function driver(): BelongsTo { return $this->belongsTo(User::class, 'driver_id'); }
    public function items(): HasMany { return $this->hasMany(VehicleInspectionItem::class, 'inspection_id'); }
}
