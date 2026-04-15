<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class TukangJagaItemDelivery extends Model {
    use HasUuids;
    protected $fillable = [
        'order_id','shift_id','delivered_by','delivered_by_role',
        'received_by','status',
        'delivered_at','received_at',
        'family_confirmed_at','family_confirmed_by',
        'delivery_notes','family_notes',
        'delivery_photo_path','receipt_photo_path',
    ];
    protected $casts = [
        'delivered_at'=>'datetime','received_at'=>'datetime',
        'family_confirmed_at'=>'datetime',
    ];
    public function order() { return $this->belongsTo(Order::class); }
    public function shift() { return $this->belongsTo(TukangJagaShift::class); }
    public function deliveredByUser() { return $this->belongsTo(User::class, 'delivered_by'); }
    public function receivedByUser() { return $this->belongsTo(User::class, 'received_by'); }
    public function familyConfirmedByUser() { return $this->belongsTo(User::class, 'family_confirmed_by'); }
    public function items() { return $this->hasMany(TukangJagaDeliveryItem::class, 'delivery_id'); }
}
