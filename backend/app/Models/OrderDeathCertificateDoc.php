<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class OrderDeathCertificateDoc extends Model
{
    use HasUuids;

    protected $fillable = [
        'order_id', 'nama_almarhum', 'catatan',
        'diterima_sm_tanggal', 'yang_menyerahkan_name', 'penerima_sm_id',
        'penerima_sm_signed_at', 'diterima_keluarga_tanggal',
        'penerima_keluarga_name', 'penerima_keluarga_signed_at',
    ];

    protected $casts = [
        'diterima_sm_tanggal' => 'date',
        'penerima_sm_signed_at' => 'datetime',
        'diterima_keluarga_tanggal' => 'date',
        'penerima_keluarga_signed_at' => 'datetime',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderDeathCertDocItem::class, 'death_cert_id');
    }

    public function penerimaSm(): BelongsTo
    {
        return $this->belongsTo(User::class, 'penerima_sm_id');
    }
}
