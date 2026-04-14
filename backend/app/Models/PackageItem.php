<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Support\Str;

class PackageItem extends Model
{
    use HasFactory;

    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'package_id',
        'stock_item_id',
        'item_name',
        'quantity',
        'unit',
        'category',
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

    public function package()
    {
        return $this->belongsTo(Package::class);
    }

    public function stockItem()
    {
        return $this->belongsTo(StockItem::class);
    }
}
