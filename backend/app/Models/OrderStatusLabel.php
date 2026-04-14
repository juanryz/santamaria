<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class OrderStatusLabel extends Model
{
    use HasUuids;

    protected $fillable = [
        'status_code', 'consumer_label', 'consumer_description',
        'internal_label', 'icon', 'color', 'sort_order',
        'show_to_consumer', 'show_map_tracking', 'is_active',
    ];

    protected $casts = [
        'show_to_consumer' => 'boolean',
        'show_map_tracking' => 'boolean',
        'is_active' => 'boolean',
    ];

    public static function getLabel(string $statusCode, bool $forConsumer = false): ?string
    {
        $label = self::where('status_code', $statusCode)->first();
        if (!$label) return null;
        return $forConsumer ? $label->consumer_label : $label->internal_label;
    }

    public static function getConsumerStatuses(): array
    {
        return self::where('is_active', true)
            ->where('show_to_consumer', true)
            ->orderBy('sort_order')
            ->get()
            ->toArray();
    }
}
