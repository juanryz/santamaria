<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class StockInterLocationTransfer extends Model
{
    use HasUuids;

    protected $table = 'stock_inter_location_transfers';

    protected $fillable = [
        'from_owner_role', 'to_owner_role',
        'stock_item_id', 'quantity',
        'requested_by', 'approved_by', 'transferred_by', 'received_by',
        'requested_at', 'transferred_at', 'received_at',
        'photo_evidence_id',
        'source_supplier_id', 'source_consignment_batch',
        'status', 'notes',
    ];

    protected $casts = [
        'quantity' => 'decimal:2',
        'requested_at' => 'datetime',
        'transferred_at' => 'datetime',
        'received_at' => 'datetime',
    ];

    public function stockItem() { return $this->belongsTo(StockItem::class); }
    public function requestedByUser() { return $this->belongsTo(User::class, 'requested_by'); }
    public function approvedByUser() { return $this->belongsTo(User::class, 'approved_by'); }
    public function transferredByUser() { return $this->belongsTo(User::class, 'transferred_by'); }
    public function receivedByUser() { return $this->belongsTo(User::class, 'received_by'); }
    public function sourceSupplier() { return $this->belongsTo(User::class, 'source_supplier_id'); }
    public function photoEvidence() { return $this->belongsTo(PhotoEvidence::class); }

    public function isPending(): bool { return in_array($this->status, ['requested','approved','in_transit']); }
    public function isConsignment(): bool { return !empty($this->source_supplier_id); }
}
