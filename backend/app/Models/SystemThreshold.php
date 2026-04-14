<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SystemThreshold extends Model
{
    public $incrementing = false;
    protected $keyType   = 'string';
    public $timestamps   = false;

    protected $fillable = [
        'id',
        'key',
        'value',
        'unit',
        'description',
        'updated_by',
        'updated_at',
    ];

    protected $casts = [
        'value'      => 'decimal:2',
        'updated_at' => 'datetime',
    ];

    public function updatedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    /** Convenience: get threshold value by key */
    public static function getValue(string $key, float $default = 0): float
    {
        return (float) (self::where('key', $key)->value('value') ?? $default);
    }
}
