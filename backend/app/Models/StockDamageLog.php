<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class StockDamageLog extends Model
{
    use HasUuids;

    protected $table = 'stock_damage_logs';

    protected $fillable = [
        'stock_item_id', 'order_id', 'barcode_scanned',
        'reported_by', 'reported_role',
        'quantity_damaged', 'damage_level', 'estimated_loss_amount',
        'damage_photo_evidence_id', 'damage_description',
        'responsible_party', 'responsible_user_id',
        'status', 'resolution_notes', 'resolved_by', 'resolved_at',
    ];

    protected $casts = [
        'quantity_damaged' => 'decimal:2',
        'estimated_loss_amount' => 'decimal:2',
        'resolved_at' => 'datetime',
    ];

    public function stockItem() { return $this->belongsTo(StockItem::class); }
    public function order() { return $this->belongsTo(Order::class); }
    public function reporter() { return $this->belongsTo(User::class, 'reported_by'); }
    public function responsibleUser() { return $this->belongsTo(User::class, 'responsible_user_id'); }
    public function resolver() { return $this->belongsTo(User::class, 'resolved_by'); }
    public function photoEvidence() { return $this->belongsTo(PhotoEvidence::class, 'damage_photo_evidence_id'); }
}
