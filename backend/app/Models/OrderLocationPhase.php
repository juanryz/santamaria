<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class OrderLocationPhase extends Model
{
    use HasUuids;

    protected $table = 'order_location_phases';

    protected $fillable = [
        'order_id', 'phase_sequence', 'funeral_home_id',
        'start_date', 'end_date', 'activities', 'notes',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
    ];

    public function order() { return $this->belongsTo(Order::class); }
    public function funeralHome() { return $this->belongsTo(FuneralHome::class); }
}
