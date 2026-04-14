<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Support\Str;

class ConsumerStorageQuota extends Model
{
    use HasFactory;

    protected $table = 'consumer_storage_quota';
    protected $keyType = 'string';
    public $incrementing = false;
    public $timestamps = false;

    protected $fillable = [
        'user_id',
        'quota_bytes',
        'used_bytes',
        'updated_at',
    ];

    protected $casts = [
        'quota_bytes' => 'integer',
        'used_bytes' => 'integer',
        'updated_at' => 'datetime',
    ];

    protected static function boot()
    {
        parent::boot();
        static::creating(function ($model) {
            if (empty($model->{$model->getKeyName()})) {
                $model->{$model->getKeyName()} = (string) Str::uuid();
            }
            $model->updated_at = now();
        });
        static::updating(function ($model) {
            $model->updated_at = now();
        });
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
