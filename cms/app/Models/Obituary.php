<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class Obituary extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $table = 'obituaries';

    protected $guarded = ['id'];

    protected $casts = [
        'deceased_dob' => 'date',
        'deceased_dod' => 'date',
        'funeral_datetime' => 'datetime',
        'prayer_datetime' => 'datetime',
        'published_at' => 'datetime',
        'is_featured' => 'boolean',
        'view_count' => 'integer',
    ];

    protected static function booted(): void
    {
        static::saving(function (Obituary $o) {
            if (empty($o->slug) && !empty($o->deceased_name)) {
                $o->slug = Str::slug($o->deceased_name) . '-' . Str::lower(Str::random(6));
            }
            if ($o->deceased_dob && $o->deceased_dod) {
                $o->deceased_age = Carbon::parse($o->deceased_dob)->diffInYears(Carbon::parse($o->deceased_dod));
            }
        });
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function getDeceasedPhotoUrlAttribute(): ?string
    {
        return $this->deceased_photo_path ? Storage::url($this->deceased_photo_path) : null;
    }

    protected $appends = ['deceased_photo_url'];
}
