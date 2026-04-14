<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WaMessageLog extends Model
{
    use HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'template_id', 'order_id', 'sent_by',
        'recipient_phone', 'recipient_name', 'message_content', 'sent_at',
    ];

    protected $casts = [
        'sent_at' => 'datetime',
    ];

    public function template(): BelongsTo
    {
        return $this->belongsTo(WaMessageTemplate::class, 'template_id');
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }
}
