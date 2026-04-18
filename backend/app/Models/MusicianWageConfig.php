<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class MusicianWageConfig extends Model
{
    use HasUuids;

    protected $table = 'musician_wage_config';

    protected $fillable = [
        'role_label', 'rate_per_session_per_person',
        'effective_date', 'end_date', 'is_active', 'notes',
    ];

    protected $casts = [
        'rate_per_session_per_person' => 'decimal:2',
        'effective_date' => 'date',
        'end_date' => 'date',
        'is_active' => 'boolean',
    ];

    public function scopeActive($query) { return $query->where('is_active', true); }
}
