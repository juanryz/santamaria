<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class OrderAddOn extends Model
{
    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'order_id',
        'add_on_service_id',
        'price_at_time',
        'quantity',
    ];

    protected $casts = [
        'id' => 'string',
        'price_at_time' => 'decimal:2',
        'quantity' => 'integer',
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

    public function addOnService()
    {
        return $this->belongsTo(AddOnService::class, 'add_on_service_id');
    }
}
