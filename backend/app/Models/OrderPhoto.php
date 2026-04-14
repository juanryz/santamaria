<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class OrderPhoto extends Model
{
    protected $keyType = 'string';
    public $incrementing = false;

    // Schema only has created_at, no updated_at
    const UPDATED_AT = null;

    protected $fillable = [
        'order_id',
        'uploaded_by',
        'file_path',
        'file_name',
        'file_size_bytes',
        'file_type',
        'category',
        'source',
        'drive_link',
        'caption',
    ];

    protected $casts = [
        'id' => 'string',
        'file_size_bytes' => 'integer',
    ];

    protected static function boot()
    {
        parent::boot();
        static::creating(function ($model) {
            if (empty($model->{$model->getKeyName()})) {
                $model->{$model->getKeyName()} = (string) Str::uuid();
            }
        });
    }

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function uploader()
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }
}
