<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CoffinOrder extends Model
{
    use HasUuids;

    protected $fillable = [
        'coffin_order_number', 'order_id', 'nama_pemesan', 'kode_peti',
        'ukuran', 'warna', 'finishing_type', 'status',
        'pemberi_order_id', 'tukang_busa_name', 'tukang_amplas_name',
        'tukang_finishing_name', 'qc_officer_id',
        'mulai_busa', 'selesai_busa', 'mulai_finishing', 'selesai_finishing',
        'qc_date', 'qc_notes', 'notes',
    ];

    protected $casts = [
        'mulai_busa' => 'date',
        'selesai_busa' => 'date',
        'mulai_finishing' => 'date',
        'selesai_finishing' => 'date',
        'qc_date' => 'date',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function pemberiOrder(): BelongsTo
    {
        return $this->belongsTo(User::class, 'pemberi_order_id');
    }

    public function qcOfficer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'qc_officer_id');
    }

    public function stages(): HasMany
    {
        return $this->hasMany(CoffinOrderStage::class)->orderBy('stage_number');
    }

    public function qcResults(): HasMany
    {
        return $this->hasMany(CoffinQcResult::class);
    }
}
