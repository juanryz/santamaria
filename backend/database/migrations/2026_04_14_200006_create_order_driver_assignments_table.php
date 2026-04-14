<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_driver_assignments', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->uuid('leg_master_id');
            $table->uuid('driver_id');
            $table->uuid('vehicle_id')->nullable();
            $table->smallInteger('leg_sequence');

            // Lokasi
            $table->string('origin_label', 255);
            $table->string('destination_label', 255);
            $table->decimal('origin_lat', 10, 8)->nullable();
            $table->decimal('origin_lng', 11, 8)->nullable();
            $table->decimal('destination_lat', 10, 8)->nullable();
            $table->decimal('destination_lng', 11, 8)->nullable();

            // Status
            $table->string('status', 50)->default('assigned');
            // assigned → departed → arrived → completed | cancelled

            // Timestamps
            $table->timestamp('assigned_at')->useCurrent();
            $table->timestamp('departed_at')->nullable();
            $table->timestamp('arrived_at')->nullable();
            $table->timestamp('completed_at')->nullable();

            // Bukti
            $table->text('proof_photo_path')->nullable();
            $table->text('notes')->nullable();

            // KM tracking
            $table->decimal('km_start', 10, 2)->nullable();
            $table->decimal('km_end', 10, 2)->nullable();

            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('leg_master_id')->references('id')->on('trip_leg_master');
            $table->foreign('driver_id')->references('id')->on('users');
            $table->foreign('vehicle_id')->references('id')->on('vehicles');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_driver_assignments');
    }
};
