<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class ConsumerPaymentReminder extends Model
{
    use HasUuids;

    protected $table = 'consumer_payment_reminders';

    public $timestamps = false;

    protected $fillable = [
        'order_id', 'reminder_day', 'reminder_date',
        'sent_via', 'sent_by', 'recipient_phone',
        'template_used', 'message_content',
        'consumer_responded', 'response_notes',
        'created_at',
    ];

    protected $casts = [
        'reminder_date' => 'date',
        'consumer_responded' => 'boolean',
        'created_at' => 'datetime',
    ];

    public function order() { return $this->belongsTo(Order::class); }
    public function sentByUser() { return $this->belongsTo(User::class, 'sent_by'); }
}
