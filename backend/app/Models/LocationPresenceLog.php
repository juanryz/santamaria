<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class LocationPresenceLog extends Model
{
    use HasUuids;

    protected $table = 'location_presence_logs';

    public $timestamps = false; // only created_at

    protected $fillable = [
        'order_id', 'user_id', 'user_role',
        'location_type', 'location_name', 'location_ref_id',
        'action', 'timestamp',
        'latitude', 'longitude',
        'photo_evidence_id', 'notes',
    ];

    protected $casts = [
        'timestamp' => 'datetime',
        'latitude' => 'decimal:7',
        'longitude' => 'decimal:7',
        'created_at' => 'datetime',
    ];

    public function order() { return $this->belongsTo(Order::class); }
    public function user() { return $this->belongsTo(User::class); }
    public function photoEvidence() { return $this->belongsTo(PhotoEvidence::class); }

    public function scopeCheckIn($query)
    {
        return $query->where('action', 'check_in');
    }

    public function scopeCheckOut($query)
    {
        return $query->where('action', 'check_out');
    }

    public function scopeForOrder($query, string $orderId)
    {
        return $query->where('order_id', $orderId);
    }

    public function scopeForUser($query, string $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function isCheckIn(): bool
    {
        return $this->action === 'check_in';
    }
}
