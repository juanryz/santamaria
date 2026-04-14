<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderFieldTeamPayment extends Model
{
    protected $fillable = [
        'order_id',
        'name',
        'role_description',
        'phone',
        'amount',
        'payment_method',
        'payment_status',
        'is_absent',
        'paid_at',
        'paid_by',
        'receipt_path',
        'notes',
    ];

    protected $casts = [
        'amount'    => 'decimal:2',
        'paid_at'   => 'datetime',
        'is_absent' => 'boolean',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function paidByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'paid_by');
    }
}
