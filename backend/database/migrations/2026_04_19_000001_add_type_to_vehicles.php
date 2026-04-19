<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('vehicles', function (Blueprint $table) {
            // Dipakai oleh admin fleet management UI (jenazah/ambulans/operasional)
            // dan AssignDriverToOrder job (filter 'jenazah' untuk pool mobil jenazah).
            $table->string('type', 30)->default('jenazah')->after('model');
        });
    }

    public function down(): void
    {
        Schema::table('vehicles', function (Blueprint $table) {
            $table->dropColumn('type');
        });
    }
};
