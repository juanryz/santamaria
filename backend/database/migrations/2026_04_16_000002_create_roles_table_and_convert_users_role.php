<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ── 1. Create roles table ──────────────────────────────────────────────
        Schema::create('roles', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('slug', 100)->unique();
            $table->string('label', 255);
            $table->text('description')->nullable();
            $table->boolean('is_system')->default(false);
            $table->boolean('is_active')->default(true);

            // Feature flags
            $table->boolean('can_have_inventory')->default(false);
            $table->boolean('is_vendor')->default(false);
            $table->boolean('is_viewer_only')->default(false);
            $table->boolean('can_manage_orders')->default(false);
            $table->boolean('receives_order_alarm')->default(false);

            // JSON permissions (extra)
            $table->jsonb('permissions')->default('[]');

            // UI display
            $table->string('color_hex', 7)->nullable();
            $table->string('icon_name', 100)->nullable();
            $table->integer('sort_order')->default(99);

            $table->timestamps();
        });

        // ── 2. Convert users.role from enum to varchar ────────────────────────
        // PostgreSQL: change enum column to varchar without data loss
        DB::statement('ALTER TABLE users ALTER COLUMN role TYPE VARCHAR(100)');

        // ── 3. Seed default (system) roles ────────────────────────────────────
        $now = now();

        $roles = [
            [
                'slug'                  => 'super_admin',
                'label'                 => 'Super Admin',
                'is_system'             => true,
                'sort_order'            => 1,
                'can_have_inventory'    => false,
                'is_vendor'             => false,
                'is_viewer_only'        => false,
                'can_manage_orders'     => false,
                'receives_order_alarm'  => false,
                'color_hex'             => '#7C3AED',
                'icon_name'             => 'admin_panel_settings',
            ],
            [
                'slug'                  => 'consumer',
                'label'                 => 'Konsumen',
                'is_system'             => true,
                'sort_order'            => 2,
                'can_have_inventory'    => false,
                'is_vendor'             => false,
                'is_viewer_only'        => false,
                'can_manage_orders'     => false,
                'receives_order_alarm'  => false,
                'color_hex'             => '#3B82F6',
                'icon_name'             => 'person',
            ],
            [
                'slug'                  => 'service_officer',
                'label'                 => 'Service Officer',
                'is_system'             => true,
                'sort_order'            => 3,
                'can_have_inventory'    => false,
                'is_vendor'             => false,
                'is_viewer_only'        => false,
                'can_manage_orders'     => true,
                'receives_order_alarm'  => true,
                'color_hex'             => '#0EA5E9',
                'icon_name'             => 'support_agent',
            ],
            [
                'slug'                  => 'admin',
                'label'                 => 'Admin',
                'is_system'             => true,
                'sort_order'            => 4,
                'can_have_inventory'    => false,
                'is_vendor'             => false,
                'is_viewer_only'        => false,
                'can_manage_orders'     => true,
                'receives_order_alarm'  => false,
                'color_hex'             => '#6366F1',
                'icon_name'             => 'manage_accounts',
            ],
            [
                'slug'                  => 'gudang',
                'label'                 => 'Gudang',
                'is_system'             => true,
                'sort_order'            => 5,
                'can_have_inventory'    => true,
                'is_vendor'             => false,
                'is_viewer_only'        => false,
                'can_manage_orders'     => false,
                'receives_order_alarm'  => true,
                'color_hex'             => '#F59E0B',
                'icon_name'             => 'warehouse',
            ],
            [
                'slug'                  => 'purchasing',
                'label'                 => 'Purchasing',
                'is_system'             => true,
                'sort_order'            => 6,
                'can_have_inventory'    => false,
                'is_vendor'             => false,
                'is_viewer_only'        => false,
                'can_manage_orders'     => true,
                'receives_order_alarm'  => false,
                'color_hex'             => '#10B981',
                'icon_name'             => 'shopping_cart',
            ],
            [
                'slug'                  => 'driver',
                'label'                 => 'Driver',
                'is_system'             => true,
                'sort_order'            => 7,
                'can_have_inventory'    => false,
                'is_vendor'             => false,
                'is_viewer_only'        => false,
                'can_manage_orders'     => false,
                'receives_order_alarm'  => true,
                'color_hex'             => '#EF4444',
                'icon_name'             => 'local_shipping',
            ],
            [
                'slug'                  => 'dekor',
                'label'                 => 'Dekor / La Fiore',
                'is_system'             => true,
                'sort_order'            => 8,
                'can_have_inventory'    => true,
                'is_vendor'             => true,
                'is_viewer_only'        => false,
                'can_manage_orders'     => false,
                'receives_order_alarm'  => true,
                'color_hex'             => '#EC4899',
                'icon_name'             => 'local_florist',
            ],
            [
                'slug'                  => 'konsumsi',
                'label'                 => 'Konsumsi',
                'is_system'             => true,
                'sort_order'            => 9,
                'can_have_inventory'    => true,
                'is_vendor'             => true,
                'is_viewer_only'        => false,
                'can_manage_orders'     => false,
                'receives_order_alarm'  => true,
                'color_hex'             => '#F97316',
                'icon_name'             => 'restaurant',
            ],
            [
                'slug'                  => 'supplier',
                'label'                 => 'Supplier',
                'is_system'             => true,
                'sort_order'            => 10,
                'can_have_inventory'    => false,
                'is_vendor'             => true,
                'is_viewer_only'        => false,
                'can_manage_orders'     => false,
                'receives_order_alarm'  => false,
                'color_hex'             => '#84CC16',
                'icon_name'             => 'store',
            ],
            [
                'slug'                  => 'owner',
                'label'                 => 'Owner',
                'is_system'             => true,
                'sort_order'            => 11,
                'can_have_inventory'    => false,
                'is_vendor'             => false,
                'is_viewer_only'        => false,
                'can_manage_orders'     => true,
                'receives_order_alarm'  => false,
                'color_hex'             => '#8B5CF6',
                'icon_name'             => 'business_center',
            ],
            [
                'slug'                  => 'pemuka_agama',
                'label'                 => 'Pemuka Agama',
                'is_system'             => true,
                'sort_order'            => 12,
                'can_have_inventory'    => false,
                'is_vendor'             => true,
                'is_viewer_only'        => false,
                'can_manage_orders'     => false,
                'receives_order_alarm'  => true,
                'color_hex'             => '#A78BFA',
                'icon_name'             => 'church',
            ],
            [
                'slug'                  => 'hrd',
                'label'                 => 'HRD',
                'is_system'             => true,
                'sort_order'            => 13,
                'can_have_inventory'    => false,
                'is_vendor'             => false,
                'is_viewer_only'        => false,
                'can_manage_orders'     => false,
                'receives_order_alarm'  => false,
                'color_hex'             => '#14B8A6',
                'icon_name'             => 'badge',
            ],
            [
                'slug'                  => 'viewer',
                'label'                 => 'Viewer',
                'is_system'             => true,
                'sort_order'            => 14,
                'can_have_inventory'    => false,
                'is_vendor'             => false,
                'is_viewer_only'        => true,
                'can_manage_orders'     => false,
                'receives_order_alarm'  => false,
                'color_hex'             => '#94A3B8',
                'icon_name'             => 'visibility',
            ],
            [
                'slug'                  => 'tukang_foto',
                'label'                 => 'Tukang Foto',
                'is_system'             => true,
                'sort_order'            => 15,
                'can_have_inventory'    => false,
                'is_vendor'             => true,
                'is_viewer_only'        => false,
                'can_manage_orders'     => false,
                'receives_order_alarm'  => true,
                'color_hex'             => '#F472B6',
                'icon_name'             => 'photo_camera',
            ],
            [
                'slug'                  => 'tukang_angkat_peti',
                'label'                 => 'Tukang Angkat Peti',
                'is_system'             => true,
                'sort_order'            => 16,
                'can_have_inventory'    => false,
                'is_vendor'             => true,
                'is_viewer_only'        => false,
                'can_manage_orders'     => false,
                'receives_order_alarm'  => true,
                'color_hex'             => '#78716C',
                'icon_name'             => 'fitness_center',
            ],
            [
                'slug'                  => 'laviore',
                'label'                 => 'La Fiore',
                'is_system'             => true,
                'sort_order'            => 17,
                'can_have_inventory'    => true,
                'is_vendor'             => true,
                'is_viewer_only'        => false,
                'can_manage_orders'     => false,
                'receives_order_alarm'  => true,
                'color_hex'             => '#DB2777',
                'icon_name'             => 'spa',
            ],
            [
                'slug'                  => 'tukang_jaga',
                'label'                 => 'Tukang Jaga',
                'is_system'             => true,
                'sort_order'            => 19,
                'can_have_inventory'    => false,
                'is_vendor'             => false,
                'is_viewer_only'        => false,
                'can_manage_orders'     => false,
                'receives_order_alarm'  => true,
                'color_hex'             => '#64748B',
                'icon_name'             => 'security',
            ],
            // finance is in UserRole enum but not in the spec table — add as system
            [
                'slug'                  => 'finance',
                'label'                 => 'Finance',
                'is_system'             => true,
                'sort_order'            => 18,
                'can_have_inventory'    => false,
                'is_vendor'             => false,
                'is_viewer_only'        => false,
                'can_manage_orders'     => false,
                'receives_order_alarm'  => false,
                'color_hex'             => '#22C55E',
                'icon_name'             => 'account_balance',
            ],
        ];

        foreach ($roles as $role) {
            DB::table('roles')->insert(array_merge($role, [
                'id'          => \Illuminate\Support\Str::uuid()->toString(),
                'description' => null,
                'permissions' => '[]',
                'created_at'  => $now,
                'updated_at'  => $now,
            ]));
        }
    }

    public function down(): void
    {
        // NOTE: Cannot cleanly revert VARCHAR back to PostgreSQL enum without
        // knowing all original enum values and without data migration. The role
        // column is left as VARCHAR(100) which is functionally equivalent.
        Schema::dropIfExists('roles');
    }
};
