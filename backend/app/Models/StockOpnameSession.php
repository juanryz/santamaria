<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class StockOpnameSession extends Model
{
    use HasUuids;

    protected $table = 'stock_opname_sessions';

    protected $fillable = [
        'period_year', 'period_semester', 'owner_role',
        'started_at', 'completed_at', 'performed_by',
        'total_items_counted', 'total_variance_count', 'total_variance_amount',
        'status', 'notes',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'completed_at' => 'datetime',
        'total_variance_amount' => 'decimal:2',
    ];

    public function performedByUser() { return $this->belongsTo(User::class, 'performed_by'); }
    public function items() { return $this->hasMany(StockOpnameItem::class, 'session_id'); }

    public function isCompleted(): bool { return in_array($this->status, ['completed','reviewed']); }
}
