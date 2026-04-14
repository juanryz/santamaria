<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SupplierRating extends Model
{
    protected $fillable = [
        'supplier_id',
        'procurement_request_id',
        'rated_by',
        'rating',
        'review',
    ];

    public function supplier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'supplier_id');
    }

    public function procurementRequest(): BelongsTo
    {
        return $this->belongsTo(ProcurementRequest::class);
    }

    public function ratedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'rated_by');
    }
}
