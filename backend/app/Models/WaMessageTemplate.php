<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class WaMessageTemplate extends Model
{
    use HasUuids;

    protected $fillable = [
        'template_code', 'template_name', 'target_audience',
        'trigger_moment', 'message_template', 'is_active', 'updated_by',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function logs(): HasMany
    {
        return $this->hasMany(WaMessageLog::class, 'template_id');
    }

    /**
     * Resolve template placeholders with data.
     */
    public function render(array $data): string
    {
        $message = $this->message_template;
        foreach ($data as $key => $value) {
            $message = str_replace("{{$key}}", $value ?? '', $message);
        }
        return $message;
    }
}
