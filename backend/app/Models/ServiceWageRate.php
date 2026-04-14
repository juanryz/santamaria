<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class ServiceWageRate extends Model
{
    use HasUuids;

    protected $fillable = [
        'role',
        'service_package',
        'rate_amount',
        'currency',
        'notes',
        'set_by',
        'is_active',
    ];

    protected $casts = [
        'rate_amount' => 'float',
        'is_active'   => 'boolean',
    ];

    public function setter()
    {
        return $this->belongsTo(User::class, 'set_by');
    }
}
