<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ServiceAcceptanceLetter extends Model
{
    use HasUuids;

    protected $fillable = [
        'order_id', 'letter_number', 'status',
        'pj_nama', 'pj_alamat', 'pj_no_telp', 'pj_no_ktp', 'pj_hubungan',
        'almarhum_nama', 'almarhum_tgl_lahir', 'almarhum_tgl_wafat', 'almarhum_agama', 'almarhum_alamat_terakhir',
        'paket_nama', 'paket_harga', 'layanan_tambahan', 'total_biaya',
        'lokasi_prosesi', 'lokasi_pemakaman', 'jadwal_mulai', 'estimasi_durasi_jam',
        'terms_version',
        'pj_signed_at', 'pj_signature_path',
        'saksi_nama', 'saksi_no_ktp', 'saksi_signed_at', 'saksi_signature_path',
        'sm_officer_id', 'sm_officer_nama', 'sm_signed_at', 'sm_signature_path',
        'created_by', 'notes',
    ];

    protected $casts = [
        'almarhum_tgl_lahir' => 'date',
        'almarhum_tgl_wafat' => 'date',
        'paket_harga' => 'decimal:2',
        'total_biaya' => 'decimal:2',
        'jadwal_mulai' => 'datetime',
        'pj_signed_at' => 'datetime',
        'saksi_signed_at' => 'datetime',
        'sm_signed_at' => 'datetime',
    ];

    public function order(): BelongsTo { return $this->belongsTo(Order::class); }
    public function smOfficer(): BelongsTo { return $this->belongsTo(User::class, 'sm_officer_id'); }
    public function creator(): BelongsTo { return $this->belongsTo(User::class, 'created_by'); }

    public function isFullySigned(): bool
    {
        return $this->pj_signed_at !== null && $this->sm_signed_at !== null;
    }

    public function canBeConfirmed(): bool
    {
        return $this->status === 'signed' && $this->isFullySigned();
    }
}
