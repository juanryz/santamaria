<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ExtraApprovalLine extends Model
{
    use HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'approval_id', 'line_number', 'keterangan', 'biaya', 'notes',
    ];

    protected $casts = [
        'biaya' => 'decimal:2',
    ];

    public function approval(): BelongsTo
    {
        return $this->belongsTo(OrderExtraApproval::class, 'approval_id');
    }
}
