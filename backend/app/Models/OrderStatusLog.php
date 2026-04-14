<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderStatusLog extends Model
{
    use \App\Traits\Uuids;

    protected $fillable = [
        'order_id',
        'user_id',
        'from_status',
        'to_status',
        'notes'
    ];

    const UPDATED_AT = null;
}
