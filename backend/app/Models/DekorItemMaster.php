<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class DekorItemMaster extends Model
{
    use HasUuids;

    protected $table = 'dekor_item_master';

    protected $fillable = [
        'item_code', 'item_name', 'default_unit', 'sort_order', 'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function packageLines(): HasMany
    {
        return $this->hasMany(DekorDailyPackageLine::class, 'dekor_master_id');
    }
}
