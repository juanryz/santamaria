<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ItemLocationTracking extends Model
{
    use HasUuids, HasFactory;

    protected $table = 'item_location_tracking';
    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'order_id', 'stock_item_id', 'equipment_item_id', 'item_description',
        'origin_type', 'origin_label', 'destination_type', 'destination_label',
        'current_location_type', 'current_location_label',
        'status', 'sent_by', 'sent_at', 'received_by', 'received_at',
        'return_sent_by', 'return_sent_at', 'return_received_by', 'return_received_at',
        'is_stuck', 'stuck_since', 'stuck_alert_sent',
        'ai_suggestion', 'notes',
    ];

    protected $casts = [
        'sent_at' => 'datetime',
        'received_at' => 'datetime',
        'return_sent_at' => 'datetime',
        'return_received_at' => 'datetime',
        'stuck_since' => 'datetime',
        'is_stuck' => 'boolean',
        'stuck_alert_sent' => 'boolean',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function sentBy()
    {
        return $this->belongsTo(User::class, 'sent_by');
    }

    public function receivedBy()
    {
        return $this->belongsTo(User::class, 'received_by');
    }

    public function returnSentBy()
    {
        return $this->belongsTo(User::class, 'return_sent_by');
    }

    public function returnReceivedBy()
    {
        return $this->belongsTo(User::class, 'return_received_by');
    }
}
