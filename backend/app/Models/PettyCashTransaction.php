<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class PettyCashTransaction extends Model
{
    use HasUuids;

    protected $table = 'petty_cash_transactions';

    protected $fillable = [
        'amount', 'direction', 'category', 'description',
        'reference_type', 'reference_id',
        'performed_by', 'receipt_photo_path', 'balance_after',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'balance_after' => 'decimal:2',
    ];

    public function performer() { return $this->belongsTo(User::class, 'performed_by'); }

    /** Saldo kas saat ini = balance_after dari transaksi terakhir. */
    public static function currentBalance(): float
    {
        $latest = self::orderByDesc('created_at')->first();
        return $latest ? (float) $latest->balance_after : 0.0;
    }
}
