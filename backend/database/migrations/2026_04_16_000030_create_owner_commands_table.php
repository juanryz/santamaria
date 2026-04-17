<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

/**
 * v1.36 — Owner Command System
 * Owner dapat mengirim perintah langsung ke karyawan individu atau per role.
 * Setiap perintah menghasilkan alarm notifikasi paksa di device karyawan.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('owner_commands', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('owner_id');
            $table->string('title');
            $table->text('message');
            $table->enum('priority', ['normal', 'high', 'urgent'])->default('normal');
            // Target: salah satu dari target_user_id ATAU target_role (broadcast ke semua role)
            $table->uuid('target_user_id')->nullable();
            $table->string('target_role', 50)->nullable();
            $table->enum('status', ['sent', 'partial', 'all_acknowledged'])->default('sent');
            $table->timestamps();

            $table->foreign('owner_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('target_user_id')->references('id')->on('users')->onDelete('set null');
            $table->index(['owner_id', 'created_at']);
            $table->index('target_role');
        });

        Schema::create('owner_command_receipts', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('command_id');
            $table->uuid('user_id');
            $table->timestamp('delivered_at')->nullable();
            $table->timestamp('acknowledged_at')->nullable();
            $table->text('note')->nullable(); // catatan dari karyawan saat acknowledge

            $table->foreign('command_id')->references('id')->on('owner_commands')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->unique(['command_id', 'user_id']);
            $table->index(['user_id', 'acknowledged_at']);
        });

        Schema::create('owner_command_logs', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('command_id');
            $table->uuid('actor_id')->nullable(); // user yang melakukan aksi
            $table->string('action', 50); // sent, delivered, acknowledged, cancelled
            $table->text('note')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('command_id')->references('id')->on('owner_commands')->onDelete('cascade');
            $table->index(['command_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('owner_command_logs');
        Schema::dropIfExists('owner_command_receipts');
        Schema::dropIfExists('owner_commands');
    }
};
