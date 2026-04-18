<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class StockOpnameItem extends Model
{
    use HasUuids;

    protected $table = 'stock_opname_items';

    public $timestamps = false;

    protected $fillable = [
        'session_id', 'stock_item_id',
        'system_quantity', 'actual_quantity', 'variance', 'variance_value',
        'photo_evidence_id', 'notes',
        'reconciled_at', 'adjustment_transaction_id',
        'created_at',
    ];

    protected $casts = [
        'system_quantity' => 'decimal:2',
        'actual_quantity' => 'decimal:2',
        'variance' => 'decimal:2',
        'variance_value' => 'decimal:2',
        'reconciled_at' => 'datetime',
        'created_at' => 'datetime',
    ];

    public function session() { return $this->belongsTo(StockOpnameSession::class, 'session_id'); }
    public function stockItem() { return $this->belongsTo(StockItem::class, 'stock_item_id'); }
    public function photoEvidence() { return $this->belongsTo(PhotoEvidence::class, 'photo_evidence_id'); }
    public function adjustmentTransaction() { return $this->belongsTo(StockTransaction::class, 'adjustment_transaction_id'); }
}
