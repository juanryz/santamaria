<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('users', 'device_fcm_token')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('device_fcm_token')->nullable()->after('password');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('users', 'device_fcm_token')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('device_fcm_token');
            });
        }
    }
};
