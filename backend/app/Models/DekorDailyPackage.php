<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class DekorDailyPackage extends Model
{
    use HasUuids;

    protected $table = 'dekor_daily_package';

    protected $fillable = [
        'order_id', 'form_date', 'rumah_duka',
        'selected_supplier', 'supplier_1_name', 'supplier_2_name', 'supplier_3_name',
        'total_anggaran', 'total_biaya_aktual', 'selisih',
        'div_dekorasi_id', 'administrasi_id',
        'div_dekorasi_signed_at', 'administrasi_signed_at', 'notes',
    ];

    protected $casts = [
        'form_date' => 'date',
        'total_anggaran' => 'decimal:2',
        'total_biaya_aktual' => 'decimal:2',
        'selisih' => 'decimal:2',
        'div_dekorasi_signed_at' => 'datetime',
        'administrasi_signed_at' => 'datetime',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function lines(): HasMany
    {
        return $this->hasMany(DekorDailyPackageLine::class, 'package_id');
    }

    public function divDekorasi(): BelongsTo
    {
        return $this->belongsTo(User::class, 'div_dekorasi_id');
    }
}
