<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class StockLostLog extends Model
{
    use HasUuids;

    protected $table = 'stock_lost_logs';

    protected $fillable = [
        'stock_item_id', 'order_id',
        'quantity_lost', 'estimated_loss_amount',
        'last_tukang_jaga_id', 'last_delivery_id',
        'penalty_amount', 'penalty_deducted', 'penalty_deducted_at',
        'reported_by', 'reported_at', 'status', 'notes',
    ];

    protected $casts = [
        'quantity_lost' => 'decimal:2',
        'estimated_loss_amount' => 'decimal:2',
        'penalty_amount' => 'decimal:2',
        'penalty_deducted' => 'boolean',
        'penalty_deducted_at' => 'datetime',
        'reported_at' => 'datetime',
    ];

    public function stockItem() { return $this->belongsTo(StockItem::class); }
    public function order() { return $this->belongsTo(Order::class); }
    public function lastTukangJaga() { return $this->belongsTo(User::class, 'last_tukang_jaga_id'); }
    public function reporter() { return $this->belongsTo(User::class, 'reported_by'); }
}
