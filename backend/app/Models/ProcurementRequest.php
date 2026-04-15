<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class ProcurementRequest extends Model
{
    use HasUuids;

    // Status Constants
    const STATUS_DRAFT            = 'draft';
    const STATUS_OPEN             = 'open';
    const STATUS_EVALUATING       = 'evaluating';
    const STATUS_AWARDED          = 'awarded';
    const STATUS_FINANCE_APPROVED = 'finance_approved';   // == ProcurementStatus::PURCHASING_APPROVED->value
    const STATUS_GOODS_RECEIVED   = 'goods_received';
    const STATUS_PARTIAL_RECEIVED = 'partial_received';
    const STATUS_COMPLETED        = 'completed';
    const STATUS_CANCELLED        = 'cancelled';

    protected $fillable = [
        'request_number',
        'gudang_user_id',
        'requested_by',
        'order_id',
        'item_name',
        'specification',
        'category',
        'quantity',
        'unit',
        'estimated_price',
        'max_price',
        'delivery_address',
        'needed_by',
        'quote_deadline',
        'status',
        'supplier_transaction_id',
        'finance_user_id',
        'finance_rejection_reason',
        'finance_approved_at',
        'published_at',
        'cancelled_at',
        'cancelled_reason',
    ];

    protected $casts = [
        'needed_by'           => 'datetime',
        'quote_deadline'      => 'datetime',
        'finance_approved_at' => 'datetime',
        'published_at'        => 'datetime',
        'cancelled_at'        => 'datetime',
        'estimated_price'     => 'decimal:2',
        'max_price'           => 'decimal:2',
    ];

    public function gudangUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'gudang_user_id');
    }

    public function requestedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requested_by');
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function financeUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'finance_user_id');
    }

    public function quotes(): HasMany
    {
        return $this->hasMany(SupplierQuote::class);
    }

    public function winnerQuote(): HasOne
    {
        return $this->hasOne(SupplierQuote::class)->where('status', 'awarded');
    }

    public function supplierTransaction(): HasOne
    {
        return $this->hasOne(SupplierTransaction::class);
    }

    public function ratings(): HasMany
    {
        return $this->hasMany(SupplierRating::class);
    }

    /** Generate request number PRQ-YYYYMMDD-XXXX */
    public static function generateRequestNumber(): string
    {
        $date  = now()->format('Ymd');
        $count = self::whereDate('created_at', today())->count() + 1;
        return sprintf('PRQ-%s-%04d', $date, $count);
    }
}
