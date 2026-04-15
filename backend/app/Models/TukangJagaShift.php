<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class TukangJagaShift extends Model {
    use HasUuids;
    protected $fillable = [
        'order_id','shift_number','shift_type',
        'scheduled_start','scheduled_end',
        'assigned_to','checkin_at','checkout_at','checkin_verified_by',
        'status','wage_config_id','wage_amount','wage_paid','notes',
    ];
    protected $casts = [
        'scheduled_start'=>'datetime','scheduled_end'=>'datetime',
        'checkin_at'=>'datetime','checkout_at'=>'datetime',
        'wage_amount'=>'decimal:2','wage_paid'=>'boolean',
    ];
    public function order() { return $this->belongsTo(Order::class); }
    public function assignedUser() { return $this->belongsTo(User::class, 'assigned_to'); }
    public function wageConfig() { return $this->belongsTo(TukangJagaWageConfig::class, 'wage_config_id'); }
    public function deliveries() { return $this->hasMany(TukangJagaItemDelivery::class, 'shift_id'); }

    public function isActive(): bool { return $this->status === 'active'; }
    public function canReceiveItems(): bool { return $this->status === 'active' && $this->checkin_at !== null; }
}
