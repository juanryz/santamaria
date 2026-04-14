<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class VehicleInspectionMaster extends Model
{
    use HasUuids;

    protected $table = 'vehicle_inspection_master';

    protected $fillable = [
        'category', 'item_name', 'check_type', 'sort_order', 'is_critical', 'is_active',
    ];

    protected $casts = ['is_critical' => 'boolean', 'is_active' => 'boolean'];
}
