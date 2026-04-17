<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserLocationConsent extends Model
{
    protected $primaryKey = 'user_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'agreed',
        'agreed_at',
        'ip_address',
    ];

    protected $casts = [
        'agreed'    => 'boolean',
        'agreed_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
