<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SupplierTransaction extends Model
{
    // Shipment Status Constants
    const SHIPMENT_STATUS_PENDING = 'pending_shipment';
    const SHIPMENT_STATUS_SHIPPED = 'shipped';
    const SHIPMENT_STATUS_GOODS_RECEIVED = 'goods_received';
    const SHIPMENT_STATUS_PARTIAL_RECEIVED = 'partial_received';

    // Payment Status Constants
    const PAYMENT_STATUS_UNPAID = 'unpaid';
    const PAYMENT_STATUS_PAID = 'paid';

    protected $fillable = [
        'transaction_number',
        'procurement_request_id',
        'supplier_quote_id',
        'supplier_id',
        'finance_user_id',
        'agreed_unit_price',
        'agreed_quantity',
        'agreed_total',
        'shipment_status',
        'tracking_number',
        'shipment_photo_path',
        'shipped_at',
        'received_at',
        'received_quantity',
        'received_condition',
        'received_photo_path',
        'payment_status',
        'payment_method',
        'payment_amount',
        'payment_receipt_path',
        'payment_date',
        'payment_confirmed_by_supplier',
        'payment_confirmed_at',
        'finance_approved_at',
    ];

    protected $casts = [
        'agreed_unit_price'              => 'decimal:2',
        'agreed_total'                   => 'decimal:2',
        'payment_amount'                 => 'decimal:2',
        'shipped_at'                     => 'datetime',
        'received_at'                    => 'datetime',
        'finance_approved_at'            => 'datetime',
        'payment_confirmed_at'           => 'datetime',
        'payment_confirmed_by_supplier'  => 'boolean',
    ];

    public function procurementRequest(): BelongsTo
    {
        return $this->belongsTo(ProcurementRequest::class);
    }

    public function supplierQuote(): BelongsTo
    {
        return $this->belongsTo(SupplierQuote::class, 'supplier_quote_id');
    }

    public function supplier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'supplier_id');
    }

    public function financeUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'finance_user_id');
    }

    /** Generate transaction number TRX-YYYYMMDD-XXXX */
    public static function generateTransactionNumber(): string
    {
        $date  = now()->format('Ymd');
        $count = self::whereDate('created_at', today())->count() + 1;
        return sprintf('TRX-%s-%04d', $date, $count);
    }
}
