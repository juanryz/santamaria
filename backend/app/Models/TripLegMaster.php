<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class TripLegMaster extends Model
{
    use HasUuids;

    protected $table = 'trip_leg_master';

    protected $fillable = [
        'leg_code', 'leg_name', 'description', 'category',
        'requires_proof_photo', 'triggers_gate', 'icon',
        'sort_order', 'is_active',
    ];

    protected $casts = [
        'requires_proof_photo' => 'boolean',
        'is_active' => 'boolean',
    ];
}
