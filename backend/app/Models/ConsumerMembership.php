<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class ConsumerMembership extends Model
{
    use HasUuids;

    protected $table = 'consumer_memberships';

    protected $fillable = [
        'user_id', 'membership_number', 'joined_at', 'expires_at',
        'status', 'monthly_fee',
        'last_payment_date', 'next_payment_due', 'grace_period_until',
        'total_paid',
        'cancelled_at', 'cancellation_reason', 'notes',
    ];

    protected $casts = [
        'joined_at' => 'date',
        'expires_at' => 'date',
        'last_payment_date' => 'date',
        'next_payment_due' => 'date',
        'grace_period_until' => 'date',
        'cancelled_at' => 'datetime',
        'monthly_fee' => 'decimal:2',
        'total_paid' => 'decimal:2',
    ];

    public function user() { return $this->belongsTo(User::class); }
    public function payments() { return $this->hasMany(MembershipPayment::class, 'membership_id'); }

    public function isActive(): bool { return $this->status === 'active'; }
    public function isGracePeriod(): bool { return $this->status === 'grace_period'; }

    /** v1.39 — harga paket Anggota hanya berlaku jika active ATAU grace_period. */
    public function qualifiesForMemberPricing(): bool
    {
        return in_array($this->status, ['active', 'grace_period']);
    }

    /** Generate membership number: AGG-YYYY-NNNN */
    public static function generateNumber(): string
    {
        $year = now()->format('Y');
        $last = self::where('membership_number', 'like', "AGG-{$year}-%")
            ->orderByDesc('membership_number')
            ->value('membership_number');
        $seq = $last ? ((int) substr($last, -4)) + 1 : 1;
        return sprintf('AGG-%s-%04d', $year, $seq);
    }
}
