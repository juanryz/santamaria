<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class DeathCertDocMaster extends Model
{
    use HasUuids;

    protected $table = 'death_cert_doc_master';

    protected $fillable = [
        'doc_code', 'doc_name', 'sort_order', 'is_required', 'is_active',
    ];

    protected $casts = [
        'is_required' => 'boolean',
        'is_active' => 'boolean',
    ];

    public function items(): HasMany
    {
        return $this->hasMany(OrderDeathCertDocItem::class, 'doc_master_id');
    }
}
