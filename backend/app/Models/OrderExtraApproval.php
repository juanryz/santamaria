<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class OrderExtraApproval extends Model
{
    use HasUuids;

    protected $fillable = [
        'order_id', 'nama_almarhum', 'total_biaya',
        'pj_nama', 'pj_alamat', 'pj_no_telp', 'pj_hub_alm',
        'pj_signed_at', 'pj_signature_path', 'tanggal',
        'so_id', 'approved', 'approved_at', 'notes',
    ];

    protected $casts = [
        'tanggal' => 'date',
        'total_biaya' => 'decimal:2',
        'approved' => 'boolean',
        'approved_at' => 'datetime',
        'pj_signed_at' => 'datetime',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function so(): BelongsTo
    {
        return $this->belongsTo(User::class, 'so_id');
    }

    public function lines(): HasMany
    {
        return $this->hasMany(ExtraApprovalLine::class, 'approval_id');
    }
}
