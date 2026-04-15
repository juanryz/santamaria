<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FinancialTransaction extends Model
{
    use HasUuids;

    protected $fillable = [
        'transaction_type', 'reference_type', 'reference_id', 'order_id',
        'amount', 'direction', 'currency', 'category', 'description',
        'transaction_date', 'recorded_at', 'recorded_by',
        'is_correction', 'original_transaction_id', 'correction_reason', 'corrected_at', 'corrected_by',
        'is_void', 'voided_at', 'voided_by', 'void_reason',
        'metadata',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'transaction_date' => 'date',
        'recorded_at' => 'datetime',
        'corrected_at' => 'datetime',
        'voided_at' => 'datetime',
        'is_correction' => 'boolean',
        'is_void' => 'boolean',
        'metadata' => 'array',
    ];

    public function order(): BelongsTo { return $this->belongsTo(Order::class); }
    public function recordedBy(): BelongsTo { return $this->belongsTo(User::class, 'recorded_by'); }
    public function correctedBy(): BelongsTo { return $this->belongsTo(User::class, 'corrected_by'); }
    public function voidedBy(): BelongsTo { return $this->belongsTo(User::class, 'voided_by'); }
    public function originalTransaction(): BelongsTo { return $this->belongsTo(self::class, 'original_transaction_id'); }

    public function scopeActive($query) { return $query->where('is_void', false); }
    public function scopeIncome($query) { return $query->active()->where('direction', 'in'); }
    public function scopeExpense($query) { return $query->active()->where('direction', 'out'); }
    public function scopePeriod($query, int $year, ?int $month = null)
    {
        $query->whereYear('transaction_date', $year);
        if ($month) $query->whereMonth('transaction_date', $month);
        return $query;
    }
}
