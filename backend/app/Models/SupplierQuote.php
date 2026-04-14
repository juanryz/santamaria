<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SupplierQuote extends Model
{
    // Status Constants
    const STATUS_SUBMITTED = 'submitted';
    const STATUS_UNDER_REVIEW = 'under_review';
    const STATUS_AWARDED = 'awarded';
    const STATUS_REJECTED = 'rejected';
    const STATUS_CANCELLED = 'cancelled';
    const STATUS_SHIPPED = 'shipped';
    const STATUS_COMPLETED = 'completed';

    protected $fillable = [
        'procurement_request_id',
        'supplier_id',
        'unit_price',
        'total_price',
        'brand',
        'description',
        'photo_path',
        'estimated_delivery_days',
        'warranty_info',
        'terms',
        'status',
        'ai_is_reasonable',
        'ai_market_price',
        'ai_variance_pct',
        'ai_analysis',
        'ai_analyzed_at',
        'tracking_number',
        'shipment_photo_path',
        'shipped_at',
    ];

    protected $casts = [
        'unit_price'        => 'decimal:2',
        'total_price'       => 'decimal:2',
        'ai_market_price'   => 'decimal:2',
        'ai_variance_pct'   => 'decimal:2',
        'ai_is_reasonable'  => 'boolean',
        'ai_analyzed_at'    => 'datetime',
        'shipped_at'        => 'datetime',
    ];

    public function procurementRequest(): BelongsTo
    {
        return $this->belongsTo(ProcurementRequest::class);
    }

    public function supplier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'supplier_id');
    }

    public function transaction(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(SupplierTransaction::class, 'supplier_quote_id');
    }
}
