<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class OrderMusicianSession extends Model
{
    use HasUuids;

    protected $table = 'order_musician_sessions';

    protected $fillable = [
        'order_id', 'session_date', 'session_type',
        'session_start_time', 'session_end_time', 'location',
        'musician_count', 'rate_per_person', 'total_wage',
        'musicians_user_ids', 'notes',
    ];

    protected $casts = [
        'session_date' => 'date',
        'rate_per_person' => 'decimal:2',
        'total_wage' => 'decimal:2',
        'musicians_user_ids' => 'array',
    ];

    public function order() { return $this->belongsTo(Order::class); }

    public function calculateTotal(): void
    {
        $this->total_wage = (int) $this->musician_count * (float) $this->rate_per_person;
    }
}
