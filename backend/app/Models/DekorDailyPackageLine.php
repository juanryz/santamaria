<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DekorDailyPackageLine extends Model
{
    use HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'package_id', 'dekor_master_id', 'anggaran_pendapatan', 'qty',
        'biaya_supplier_1', 'biaya_supplier_2', 'biaya_supplier_3', 'notes',
    ];

    protected $casts = [
        'anggaran_pendapatan' => 'decimal:2',
        'qty' => 'decimal:2',
        'biaya_supplier_1' => 'decimal:2',
        'biaya_supplier_2' => 'decimal:2',
        'biaya_supplier_3' => 'decimal:2',
    ];

    public function package(): BelongsTo
    {
        return $this->belongsTo(DekorDailyPackage::class, 'package_id');
    }

    public function dekorMaster(): BelongsTo
    {
        return $this->belongsTo(DekorItemMaster::class, 'dekor_master_id');
    }
}
