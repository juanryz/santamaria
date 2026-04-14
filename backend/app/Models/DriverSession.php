<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DriverSession extends Model
{
    use \App\Traits\Uuids;

    protected $fillable = [
        'driver_id',
        'started_at',
        'ended_at',
        'total_distance_km'
    ];

    public $timestamps = false;
}
