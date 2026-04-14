<?php

namespace App\Models;

use App\Models\PurchaseOrderSupplierQuote;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Support\Str;

class PurchaseOrder extends Model
{
    use HasFactory;

    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'order_id',
        'gudang_user_id',
        'item_name',
        'quantity',
        'unit',
        'proposed_price',
        'market_price',
        'price_variance_pct',
        'is_anomaly',
        'ai_analysis',
        'status',
        'finance_user_id',
        'finance_notes',
        'finance_reviewed_at',
        'owner_decision',
        'owner_notes',
        'owner_decided_at',
        'supplier_name',
        'supplier_phone',
        'completed_at',
    ];

    protected $casts = [
        'id' => 'string',
        'proposed_price' => 'decimal:2',
        'market_price' => 'decimal:2',
        'price_variance_pct' => 'decimal:2',
        'is_anomaly' => 'boolean',
        'finance_reviewed_at' => 'datetime',
        'owner_decided_at' => 'datetime',
        'completed_at' => 'datetime',
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

    public function gudangUser()
    {
        return $this->belongsTo(User::class, 'gudang_user_id');
    }

    public function financeUser()
    {
        return $this->belongsTo(User::class, 'finance_user_id');
    }

    public function supplierQuotes()
    {
        return $this->hasMany(PurchaseOrderSupplierQuote::class);
    }
}
