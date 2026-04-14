<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class Obituary extends Model
{
    use HasFactory, SoftDeletes;

    protected $keyType = 'string';
    public $incrementing = false;

    protected static function boot()
    {
        parent::boot();
        static::creating(function ($model) {
            if (empty($model->{$model->getKeyName()})) {
                $model->{$model->getKeyName()} = (string) Str::uuid();
            }
            if (empty($model->slug)) {
                $model->slug = Str::slug($model->deceased_name . '-' . $model->deceased_dod) . '-' . Str::random(6);
            }
            if ($model->deceased_dob && $model->deceased_dod) {
                $model->deceased_age = \Carbon\Carbon::parse($model->deceased_dob)
                    ->diffInYears(\Carbon\Carbon::parse($model->deceased_dod));
            }
        });
    }

    protected $fillable = [
        'slug',
        'deceased_name',
        'deceased_nickname',
        'deceased_dob',
        'deceased_dod',
        'deceased_place_of_birth',
        'deceased_religion',
        'deceased_photo_path',
        'deceased_age',
        'family_contact_name',
        'family_contact_phone',
        'family_message',
        'survived_by',
        'funeral_location',
        'funeral_datetime',
        'funeral_address',
        'cemetery_name',
        'prayer_location',
        'prayer_datetime',
        'prayer_notes',
        'order_id',
        'created_by',
        'status',
        'published_at',
        'is_featured',
        'meta_title',
        'meta_description',
    ];

    protected $casts = [
        'deceased_dob' => 'date',
        'deceased_dod' => 'date',
        'funeral_datetime' => 'datetime',
        'prayer_datetime' => 'datetime',
        'published_at' => 'datetime',
        'is_featured' => 'boolean',
    ];

    // ── Relationships ─────────────────────────────────────

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    // ── Scopes ────────────────────────────────────────────

    public function scopePublished($query)
    {
        return $query->where('status', 'published')
                     ->whereNotNull('published_at')
                     ->where('published_at', '<=', now());
    }

    public function scopeFeatured($query)
    {
        return $query->where('is_featured', true);
    }

    public function scopeRecent($query)
    {
        return $query->orderByDesc('deceased_dod');
    }
}
