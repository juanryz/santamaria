<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Support\Str;

class Order extends Model
{
    use HasFactory;

    // Main Order Status Constants
    const STATUS_PENDING = 'pending';
    const STATUS_SO_REVIEW = 'so_review';
    const STATUS_ADMIN_REVIEW = 'admin_review';
    const STATUS_APPROVED = 'approved';
    const STATUS_IN_PROGRESS = 'in_progress';
    const STATUS_COMPLETED = 'completed';
    const STATUS_CANCELLED = 'cancelled';

    // Payment Status Constants
    const PAYMENT_STATUS_UNPAID = 'unpaid';
    const PAYMENT_STATUS_PARTIAL = 'partial';
    const PAYMENT_STATUS_PAID = 'paid';
    const PAYMENT_STATUS_PROOF_UPLOADED = 'proof_uploaded';
    const PAYMENT_STATUS_PROOF_REJECTED = 'proof_rejected';

    // Department Status Constants
    const DEPT_STATUS_PENDING = 'pending';
    const DEPT_STATUS_IN_PROGRESS = 'in_progress';
    const DEPT_STATUS_READY = 'ready'; // for Gudang
    const DEPT_STATUS_CONFIRMED = 'confirmed'; // for others
    const DEPT_STATUS_DONE = 'done';

    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'order_number',
        'status',
        'pic_user_id',
        'pic_name',
        'pic_phone',
        'pic_relation',
        'pic_address',
        'deceased_name',
        'deceased_dob',
        'deceased_dod',
        'deceased_religion',
        'pickup_address',
        'pickup_lat',
        'pickup_lng',
        'destination_address',
        'destination_lat',
        'destination_lng',
        'special_notes',
        'estimated_guests',
        'package_id',
        'custom_package_name',
        'final_price',
        'so_notes',
        'so_user_id',
        'so_submitted_at',
        'scheduled_at',
        'driver_id',
        'vehicle_id',
        'admin_notes',
        'admin_user_id',
        'approved_at',
        'gudang_status',
        'gudang_confirmed_at',
        'driver_status',
        'driver_departed_at',
        'driver_arrived_pickup_at',
        'driver_arrived_destination_at',
        'dekor_status',
        'dekor_confirmed_at',
        'konsumsi_status',
        'konsumsi_confirmed_at',
        'pemuka_agama_status',
        'pemuka_agama_user_id',
        'pemuka_agama_confirmed_at',
        'payment_status',
        'payment_method',
        'payment_amount',
        'payment_notes',
        'payment_updated_at',
        'payment_updated_by',
        'invoice_path',
        'akta_path',
        'duka_text',
        'storage_used_bytes',
        'completed_at',
        'cancelled_at',
        'cancelled_reason',
        // v1.9
        'estimated_duration_hours',
        'payment_proof_path',
        'payment_proof_uploaded_at',
        'payment_verified_by',
        'auto_completed_at',
        'completion_method',
        // v1.10
        'created_by_so_channel',
        'needs_restock',
        // v1.14
        'coffin_order_id',
        'tukang_foto_id',
        'death_cert_submitted',
        'extra_approval_total',
        // v1.17
        'acceptance_signed_at',
        'acceptance_signed_by_name',
        'acceptance_signed_relation',
        'acceptance_signature_path',
        'acceptance_terms_version',
    ];

    protected $casts = [
        'id' => 'string',
        'deceased_dob' => 'date',
        'deceased_dod' => 'date',
        'scheduled_at' => 'datetime',
        'so_submitted_at' => 'datetime',
        'approved_at' => 'datetime',
        'gudang_confirmed_at' => 'datetime',
        'driver_departed_at' => 'datetime',
        'driver_arrived_pickup_at' => 'datetime',
        'driver_arrived_destination_at' => 'datetime',
        'dekor_confirmed_at' => 'datetime',
        'konsumsi_confirmed_at' => 'datetime',
        'pemuka_agama_confirmed_at' => 'datetime',
        'payment_updated_at' => 'datetime',
        'completed_at'               => 'datetime',
        'cancelled_at'               => 'datetime',
        'payment_proof_uploaded_at'  => 'datetime',
        'auto_completed_at'          => 'datetime',
        'needs_restock'              => 'boolean',
        'estimated_duration_hours'   => 'decimal:1',
        'death_cert_submitted'       => 'boolean',
        'extra_approval_total'       => 'decimal:2',
        'acceptance_signed_at'       => 'datetime',
    ];

    protected static function boot()
    {
        parent::boot();
        static::creating(function ($model) {
            if (empty($model->{$model->getKeyName()})) {
                $model->{$model->getKeyName()} = (string) Str::uuid();
            }
        });
    }

    protected $appends = ['total_price'];

    public function getTotalPriceAttribute()
    {
        $base = (float) ($this->final_price ?? 0);
        $addons = collect($this->orderAddOns)->reduce(function (float $carry, $oa) {
            return $carry + (float) $oa->price_at_time * (int) $oa->quantity;
        }, 0.0);
        return $base + $addons;
    }

    public function pic()
    {
        return $this->belongsTo(User::class, 'pic_user_id');
    }

    public function package()
    {
        return $this->belongsTo(Package::class);
    }

    public function driver()
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function soUser()
    {
        return $this->belongsTo(User::class, 'so_user_id');
    }

    public function vehicle()
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function photos()
    {
        return $this->hasMany(OrderPhoto::class);
    }

    public function orderAddOns()
    {
        return $this->hasMany(OrderAddOn::class)->with('addOnService');
    }

    public function statusLogs()
    {
        return $this->hasMany(OrderStatusLog::class);
    }

    // v1.14 relationships

    public function coffinOrder()
    {
        return $this->belongsTo(CoffinOrder::class);
    }

    public function tukangFoto()
    {
        return $this->belongsTo(User::class, 'tukang_foto_id');
    }

    public function equipmentItems()
    {
        return $this->hasMany(OrderEquipmentItem::class);
    }

    public function consumablesDaily()
    {
        return $this->hasMany(OrderConsumablesDaily::class);
    }

    public function billingItems()
    {
        return $this->hasMany(OrderBillingItem::class);
    }

    public function deathCertDoc()
    {
        return $this->hasOne(OrderDeathCertificateDoc::class);
    }

    public function extraApprovals()
    {
        return $this->hasMany(OrderExtraApproval::class);
    }

    public function fieldAttendances()
    {
        return $this->hasMany(FieldAttendance::class);
    }

    public function stockDeductions()
    {
        return $this->hasMany(OrderStockDeduction::class);
    }

    public function vehicleTripLogs()
    {
        return $this->hasMany(VehicleTripLog::class);
    }

    // v1.17 relationships

    public function driverAssignments()
    {
        return $this->hasMany(OrderDriverAssignment::class)->orderBy('leg_sequence');
    }

    public function vendorAssignments()
    {
        return $this->hasMany(OrderVendorAssignment::class);
    }

    /** Check if consumer has signed T&C */
    public function isAcceptanceSigned(): bool
    {
        return $this->acceptance_signed_at !== null;
    }

    // v1.25 relationships

    public function acceptanceLetter()
    {
        return $this->hasOne(ServiceAcceptanceLetter::class);
    }

    /** Check if acceptance letter is fully signed (gate for confirmation) */
    public function isAcceptanceLetterSigned(): bool
    {
        return $this->acceptanceLetter?->isFullySigned() ?? false;
    }
}
