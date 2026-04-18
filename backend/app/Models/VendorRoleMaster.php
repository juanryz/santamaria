<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class VendorRoleMaster extends Model
{
    use HasUuids;

    protected $table = 'vendor_role_master';

    protected $fillable = [
        'role_code', 'role_name', 'description', 'category',
        'app_role', 'is_default_in_package', 'max_per_order',
        'requires_attendance', 'requires_bukti_foto',
        'icon', 'sort_order', 'is_active',
        // v1.40
        'is_paid_by_sm',
    ];

    protected $casts = [
        'is_default_in_package' => 'boolean',
        'requires_attendance' => 'boolean',
        'requires_bukti_foto' => 'boolean',
        'is_active' => 'boolean',
        'is_paid_by_sm' => 'boolean',
    ];

    public function assignments(): HasMany
    {
        return $this->hasMany(OrderVendorAssignment::class, 'vendor_role_id');
    }
}
