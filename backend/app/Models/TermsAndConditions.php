<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TermsAndConditions extends Model
{
    use HasUuids;

    protected $table = 'terms_and_conditions';

    protected $fillable = [
        'version', 'title', 'content', 'effective_date', 'is_current', 'created_by',
    ];

    protected $casts = [
        'effective_date' => 'date',
        'is_current' => 'boolean',
    ];

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public static function current(): ?self
    {
        return self::where('is_current', true)->first();
    }
}
