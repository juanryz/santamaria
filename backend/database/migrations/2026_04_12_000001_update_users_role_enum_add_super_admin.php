<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Hapus CHECK constraint lama pada kolom role
        DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');

        // Tambahkan CHECK constraint baru yang mencakup super_admin
        $roles = implode("','", [
            'super_admin',
            'consumer',
            'service_officer',
            'admin',
            'gudang',
            'finance',
            'driver',
            'dekor',
            'konsumsi',
            'supplier',
            'owner',
            'pemuka_agama',
            'tukang_angkat_peti',
        ]);

        DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('{$roles}'))");
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');

        $roles = implode("','", [
            'consumer',
            'service_officer',
            'admin',
            'gudang',
            'finance',
            'driver',
            'dekor',
            'konsumsi',
            'supplier',
            'owner',
            'pemuka_agama',
        ]);

        DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('{$roles}'))");
    }
};
