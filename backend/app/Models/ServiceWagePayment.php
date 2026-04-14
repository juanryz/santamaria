<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class ServiceWagePayment extends Model
{
    use HasUuids;

    protected $fillable = [
        'claim_id',
        'paid_amount',
        'payment_method',
        'receipt_photo_path',
        'bank_name',
        'account_number',
        'account_holder',
        'payment_notes',
        'paid_by',
        'paid_at',
        'confirmed_by_claimant',
        'confirmed_at',
    ];

    protected $casts = [
        'paid_amount'           => 'float',
        'paid_at'               => 'datetime',
        'confirmed_by_claimant' => 'boolean',
        'confirmed_at'          => 'datetime',
    ];

    public function claim()
    {
        return $this->belongsTo(ServiceWageClaim::class, 'claim_id');
    }

    public function payer()
    {
        return $this->belongsTo(User::class, 'paid_by');
    }
}
