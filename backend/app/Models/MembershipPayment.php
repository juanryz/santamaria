<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class MembershipPayment extends Model
{
    use HasUuids;

    protected $table = 'membership_payments';

    protected $fillable = [
        'membership_id', 'payment_period_year', 'payment_period_month',
        'amount', 'payment_method', 'paid_at',
        'received_by', 'receipt_path', 'notes',
    ];

    protected $casts = [
        'paid_at' => 'datetime',
        'amount' => 'decimal:2',
    ];

    public function membership() { return $this->belongsTo(ConsumerMembership::class, 'membership_id'); }
    public function receiver() { return $this->belongsTo(User::class, 'received_by'); }
}
