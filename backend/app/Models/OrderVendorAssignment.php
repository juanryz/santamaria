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
        // v1.24/v1.40 fee tracking
        'fee', 'fee_source', 'billing_item_id',
        'wa_contacted', 'wa_contacted_at', 'wa_contacted_by',
        'declined_reason', 'activity_description',
        'estimated_duration_hours', 'field_attendance_id',
    ];

    protected $casts = [
        'assigned_at' => 'datetime',
        'confirmed_at' => 'datetime',
        'completed_at' => 'datetime',
        'scheduled_date' => 'date',
        'requested_by_consumer' => 'boolean',
        // v1.24/v1.40
        'fee' => 'decimal:2',
        'estimated_duration_hours' => 'decimal:1',
        'wa_contacted' => 'boolean',
        'wa_contacted_at' => 'datetime',
    ];

    /**
     * v1.40 — Enforce: vendor dengan is_paid_by_sm=false selalu fee=0.
     * Pemuka agama: force external source + fee=0 + user_id=null.
     * Keluarga bayar langsung, bukan via SM.
     */
    protected static function booted(): void
    {
        static::saving(function (OrderVendorAssignment $assignment) {
            $role = $assignment->vendorRole
                ?? ($assignment->vendor_role_id
                    ? VendorRoleMaster::find($assignment->vendor_role_id)
                    : null);

            if (! $role) {
                return;
            }

            // Rule universal: is_paid_by_sm=false → fee harus 0
            if ($role->is_paid_by_sm === false) {
                $assignment->fee = 0;
            }

            // Rule khusus pemuka_agama
            if ($role->role_code === 'pemuka_agama') {
                // Force external source — tidak ada pool internal SM
                if ($assignment->source === 'internal') {
                    $assignment->source = 'external_consumer';
                    $assignment->user_id = null;
                }
                // Marker note untuk UI
                $marker = '[v1.40] Keluarga bayar langsung ke pemuka agama (fee SM=0).';
                if (! str_contains((string) $assignment->notes, '[v1.40]')) {
                    $assignment->notes = trim(((string) $assignment->notes) . "\n" . $marker);
                }
            }
        });
    }

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
