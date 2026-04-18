<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class CoffinSizeMaster extends Model
{
    use HasUuids;

    protected $table = 'coffin_size_master';

    protected $fillable = [
        'size_label', 'min_length_cm', 'max_length_cm',
        'recommended_lifters_min', 'recommended_lifters_max',
        'sort_order', 'is_active',
    ];

    protected $casts = [
        'min_length_cm' => 'integer',
        'max_length_cm' => 'integer',
        'recommended_lifters_min' => 'integer',
        'recommended_lifters_max' => 'integer',
        'sort_order' => 'integer',
        'is_active' => 'boolean',
    ];

    public function orders()
    {
        return $this->hasMany(Order::class, 'coffin_size_id');
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeOrdered($query)
    {
        return $query->orderBy('sort_order');
    }
}
