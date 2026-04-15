<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class Role extends Model
{
    use HasUuids;

    protected $fillable = [
        'slug', 'label', 'description',
        'is_system', 'is_active',
        'can_have_inventory', 'is_vendor', 'is_viewer_only',
        'can_manage_orders', 'receives_order_alarm',
        'permissions', 'color_hex', 'icon_name', 'sort_order',
    ];

    protected $casts = [
        'is_system'            => 'boolean',
        'is_active'            => 'boolean',
        'can_have_inventory'   => 'boolean',
        'is_vendor'            => 'boolean',
        'is_viewer_only'       => 'boolean',
        'can_manage_orders'    => 'boolean',
        'receives_order_alarm' => 'boolean',
        'permissions'          => 'array',
    ];

    public function users()
    {
        return $this->hasMany(User::class, 'role', 'slug');
    }

    public static function findBySlug(string $slug): ?self
    {
        return static::where('slug', $slug)->first();
    }
}
