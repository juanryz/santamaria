<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

return new class extends Migration
{
    public function up(): void
    {
        // Add KTP/KK photo columns to orders
        Schema::table('orders', function (Blueprint $table) {
            $table->text('ktp_photo_path')->nullable()->after('notes');
            $table->text('kk_photo_path')->nullable()->after('ktp_photo_path');
        });

        // Seed missing test users for new roles
        $roles = [
            [
                'name' => 'Joko Tukang Jaga',
                'email' => 'tukang.jaga@santamaria.id',
                'phone' => '081300000001',
                'role' => 'tukang_jaga',
                'password' => Hash::make('tukang123'),
            ],
            [
                'name' => 'Slamet Petugas Akta',
                'email' => 'akta@santamaria.id',
                'phone' => '081300000002',
                'role' => 'petugas_akta',
                'password' => Hash::make('akta1234'),
            ],
            [
                'name' => 'Rudi Musisi',
                'email' => 'musisi@santamaria.id',
                'phone' => '081300000003',
                'role' => 'musisi',
                'password' => Hash::make('musisi123'),
            ],
            [
                'name' => 'Bambang Koordinator Peti',
                'email' => 'angkat.peti@santamaria.id',
                'phone' => '081300000004',
                'role' => 'tukang_angkat_peti',
                'password' => Hash::make('peti1234'),
            ],
        ];

        foreach ($roles as $user) {
            $exists = DB::table('users')->where('email', $user['email'])->exists();
            if (!$exists) {
                DB::table('users')->insert(array_merge($user, [
                    'id' => DB::raw('gen_random_uuid()'),
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]));
            }
        }
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['ktp_photo_path', 'kk_photo_path']);
        });

        DB::table('users')->whereIn('email', [
            'tukang.jaga@santamaria.id',
            'akta@santamaria.id',
            'musisi@santamaria.id',
            'angkat.peti@santamaria.id',
        ])->delete();
    }
};
