<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderDeathCertDocItem extends Model
{
    use HasUuids;

    protected $fillable = [
        'death_cert_id', 'doc_master_id', 'diterima_sm', 'diterima_keluarga', 'notes',
    ];

    protected $casts = [
        'diterima_sm' => 'boolean',
        'diterima_keluarga' => 'boolean',
    ];

    public function deathCert(): BelongsTo
    {
        return $this->belongsTo(OrderDeathCertificateDoc::class, 'death_cert_id');
    }

    public function docMaster(): BelongsTo
    {
        return $this->belongsTo(DeathCertDocMaster::class, 'doc_master_id');
    }
}
