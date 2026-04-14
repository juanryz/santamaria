<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class ServiceWageClaim extends Model
{
    use HasUuids;

    protected $fillable = [
        'order_id',
        'claimant_id',
        'claimant_role',
        'wage_rate_id',
        'claimed_amount',
        'claim_notes',
        'status',
        'reviewed_by',
        'reviewed_at',
        'approved_amount',
        'review_notes',
    ];

    protected $casts = [
        'claimed_amount'  => 'float',
        'approved_amount' => 'float',
        'reviewed_at'     => 'datetime',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function claimant()
    {
        return $this->belongsTo(User::class, 'claimant_id');
    }

    public function wageRate()
    {
        return $this->belongsTo(ServiceWageRate::class, 'wage_rate_id');
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function payment()
    {
        return $this->hasOne(ServiceWagePayment::class, 'claim_id');
    }
}
