<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('driver_locations', function (Blueprint $table) {
            $table->id();
            $table->uuid('driver_id');
            $table->uuid('order_id')->nullable();
            $table->decimal('lat', 10, 8);
            $table->decimal('lng', 11, 8);
            $table->decimal('speed', 5, 2)->nullable();
            $table->decimal('heading', 5, 2)->nullable();
            $table->decimal('accuracy', 8, 2)->nullable();
            $table->timestamp('recorded_at');
            $table->timestamp('created_at')->nullable();

            $table->foreign('driver_id')->references('id')->on('users');
            $table->foreign('order_id')->references('id')->on('orders');
            
            $table->index(['driver_id', 'recorded_at']);
        });

        Schema::create('driver_sessions', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('driver_id');
            $table->timestamp('started_at');
            $table->timestamp('ended_at')->nullable();
            $table->decimal('total_distance_km', 8, 2)->nullable();
            $table->timestamp('created_at')->nullable();

            $table->foreign('driver_id')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('driver_sessions');
        Schema::dropIfExists('driver_locations');
    }
};
