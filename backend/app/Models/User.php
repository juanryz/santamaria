<?php

namespace App\Models;

use App\Enums\UserRole;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Support\Str;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    protected $keyType = 'string';
    public $incrementing = false;

    protected static function boot()
    {
        parent::boot();
        static::creating(function ($model) {
            if (empty($model->{$model->getKeyName()})) {
                $model->{$model->getKeyName()} = (string) Str::uuid();
            }
        });
    }

    protected $fillable = [
        'name',
        'phone',
        'email',
        'role',
        'pin',
        'password',
        'is_viewer',
        'is_active',
        'is_verified_supplier',
        'device_fcm_token',
        'avatar_url',
        'religion',
        'location_lat',
        'location_lng',
        'created_by',
        // v1.10
        'so_channel',
        'supplier_rating_avg',
        'supplier_rating_count',
        'address',
        'npwp',
    ];

    protected $hidden = [
        'password',
        'pin',
        'remember_token',
    ];

    protected $casts = [
        'id' => 'string',
        'is_viewer' => 'boolean',
        'is_active' => 'boolean',
        'is_verified_supplier' => 'boolean',
        'location_lat' => 'decimal:8',
        'location_lng' => 'decimal:8',
        'password' => 'hashed',
        'pin' => 'hashed',
    ];

    public static function roles(): array
    {
        return UserRole::values();
    }

    public static function vendorRoles(): array
    {
        return UserRole::vendorValues();
    }

    public static function viewerRoles(): array
    {
        return UserRole::viewerValues();
    }

    public static function activeRoles(): array
    {
        return UserRole::activeValues();
    }

    public function isRole(UserRole $role): bool
    {
        return $this->role === $role->value;
    }

    public function isVendor(): bool
    {
        return in_array($this->role, self::vendorRoles(), true);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function storageQuota()
    {
        return $this->hasOne(ConsumerStorageQuota::class);
    }

    /** Orders where this user is the assigned driver */
    public function assignedOrders()
    {
        return $this->hasMany(Order::class, 'driver_id');
    }

    /** HRD violations for this user */
    public function hrdViolations()
    {
        return $this->hasMany(HrdViolation::class, 'violated_by');
    }

    /** Supplier ratings received */
    public function supplierRatings()
    {
        return $this->hasMany(SupplierRating::class, 'supplier_id');
    }

    // v1.14 relationships

    /** Field attendances (for vendors/tukang_foto) */
    public function fieldAttendances()
    {
        return $this->hasMany(FieldAttendance::class);
    }

    /** KPI scores */
    public function kpiScores()
    {
        return $this->hasMany(KpiScore::class);
    }

    /** KPI summaries */
    public function kpiSummaries()
    {
        return $this->hasMany(KpiUserSummary::class);
    }

    /** Helper: is this user a purchasing/finance role */
    public function isPurchasing(): bool
    {
        return in_array($this->role, [UserRole::FINANCE->value, UserRole::PURCHASING->value], true);
    }

    /** Helper: is this a viewer role */
    public function isViewer(): bool
    {
        return in_array($this->role, self::viewerRoles(), true);
    }
}
