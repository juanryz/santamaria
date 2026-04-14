<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VehicleTripLog extends Model
{
    use HasUuids;

    protected $fillable = [
        'nota_number', 'order_id', 'vehicle_id', 'driver_id',
        'atas_nama', 'alamat_penjemputan', 'tujuan', 'tempat_pemberangkatan',
        'biaya_per_km', 'waktu_pemakaian', 'hari', 'jam',
        'km_berangkat', 'km_tiba', 'km_total',
        'biaya_km', 'biaya_administrasi', 'total_biaya',
        'penyewa_name', 'penyewa_signed_at', 'sm_officer_name', 'sm_officer_signed_at',
        'notes',
    ];

    protected $casts = [
        'waktu_pemakaian' => 'datetime',
        'penyewa_signed_at' => 'datetime',
        'sm_officer_signed_at' => 'datetime',
        'biaya_per_km' => 'decimal:2',
        'km_total' => 'decimal:2',
        'total_biaya' => 'decimal:2',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'driver_id');
    }
}
