<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DriverLocation extends Model
{
    protected $fillable = [
        'driver_id',
        'order_id',
        'lat',
        'lng',
        'speed',
        'heading',
        'accuracy',
        'recorded_at'
    ];

    public $timestamps = false;
}
