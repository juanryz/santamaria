<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class UserLocation extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'latitude',
        'longitude',
        'accuracy',
        'speed',
        'heading',
        'altitude',
        'battery_level',
        'is_moving',
        'recorded_at',
    ];

    protected $casts = [
        'latitude'      => 'float',
        'longitude'     => 'float',
        'accuracy'      => 'float',
        'speed'         => 'float',
        'heading'       => 'float',
        'altitude'      => 'float',
        'is_moving'     => 'boolean',
        'recorded_at'   => 'datetime',
    ];

    public $timestamps = false;

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
