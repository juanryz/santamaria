<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderGalleryLink extends Model
{
    use HasUuids;

    protected $fillable = [
        'order_id', 'uploaded_by', 'title', 'drive_url',
        'description', 'link_type', 'is_visible_consumer', 'is_visible_so',
    ];

    protected $casts = [
        'is_visible_consumer' => 'boolean',
        'is_visible_so' => 'boolean',
    ];

    public function order(): BelongsTo { return $this->belongsTo(Order::class); }
    public function uploader(): BelongsTo { return $this->belongsTo(User::class, 'uploaded_by'); }
}
