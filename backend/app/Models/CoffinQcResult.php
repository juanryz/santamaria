<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CoffinQcResult extends Model
{
    use HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'coffin_order_id', 'criteria_master_id', 'is_passed', 'notes',
    ];

    protected $casts = [
        'is_passed' => 'boolean',
    ];

    public function coffinOrder(): BelongsTo
    {
        return $this->belongsTo(CoffinOrder::class);
    }

    public function criteriaMaster(): BelongsTo
    {
        return $this->belongsTo(CoffinQcCriteriaMaster::class, 'criteria_master_id');
    }
}
