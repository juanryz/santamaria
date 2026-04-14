<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderVendorAssignment extends Model
{
    use HasUuids;

    protected $fillable = [
        'order_id', 'vendor_role_id', 'source',
        'user_id', 'ext_name', 'ext_phone', 'ext_whatsapp',
        'ext_email', 'ext_organization', 'ext_notes',
        'assigned_at', 'assigned_by', 'requested_by_consumer',
        'scheduled_date', 'scheduled_time',
        'status', 'confirmed_at', 'completed_at', 'notes',
    ];

    protected $casts = [
        'assigned_at' => 'datetime',
        'confirmed_at' => 'datetime',
        'completed_at' => 'datetime',
        'scheduled_date' => 'date',
        'requested_by_consumer' => 'boolean',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function vendorRole(): BelongsTo
    {
        return $this->belongsTo(VendorRoleMaster::class, 'vendor_role_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function assignedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_by');
    }

    /** Get display name (internal or external). */
    public function getDisplayNameAttribute(): string
    {
        return $this->user?->name ?? $this->ext_name ?? '-';
    }

    /** Get contact phone (internal or external). */
    public function getContactPhoneAttribute(): ?string
    {
        return $this->user?->phone ?? $this->ext_phone;
    }
}
