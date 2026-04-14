<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class EquipmentLoan extends Model
{
    use HasUuids;

    protected $fillable = [
        'loan_number', 'order_id', 'nama_almarhum', 'rumah_duka',
        'cp_almarhum', 'tgl_peringatan', 'tgl_kirim', 'tgl_kembali',
        'status', 'order_by_id', 'bagian_peralatan_id', 'pengirim_id',
        'pengambil_id', 'penerima_name', 'notes',
    ];

    protected $casts = [
        'tgl_peringatan' => 'date',
        'tgl_kirim' => 'date',
        'tgl_kembali' => 'date',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderEquipmentItem::class);
    }

    public function orderBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'order_by_id');
    }

    public function bagianPeralatan(): BelongsTo
    {
        return $this->belongsTo(User::class, 'bagian_peralatan_id');
    }
}
