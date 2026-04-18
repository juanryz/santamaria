<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class PhotographerDailyWage extends Model
{
    use HasUuids;

    protected $table = 'photographer_daily_wages';

    protected $fillable = [
        'photographer_user_id', 'work_date', 'session_count', 'order_ids',
        'daily_rate', 'bonus_per_extra_session', 'total_wage',
        'status', 'finalized_at', 'paid_at', 'paid_by',
        'payment_receipt_path', 'notes',
    ];

    protected $casts = [
        'work_date' => 'date',
        'order_ids' => 'array',
        'daily_rate' => 'decimal:2',
        'bonus_per_extra_session' => 'decimal:2',
        'total_wage' => 'decimal:2',
        'finalized_at' => 'datetime',
        'paid_at' => 'datetime',
    ];

    public function photographer() { return $this->belongsTo(User::class, 'photographer_user_id'); }
    public function paidByUser() { return $this->belongsTo(User::class, 'paid_by'); }

    public function isDraft(): bool { return $this->status === 'draft'; }
    public function isPaid(): bool { return $this->status === 'paid'; }
}
