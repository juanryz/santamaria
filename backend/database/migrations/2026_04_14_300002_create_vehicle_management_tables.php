<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // KM logs (speedometer readings)
        Schema::create('vehicle_km_logs', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('vehicle_id');
            $table->uuid('driver_id');
            $table->string('log_type', 30); // start, end, refuel
            $table->decimal('km_reading', 10, 1);
            $table->text('photo_path')->nullable();
            $table->uuid('order_id')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('vehicle_id')->references('id')->on('vehicles');
            $table->foreign('driver_id')->references('id')->on('users');
            $table->foreign('order_id')->references('id')->on('orders');
        });

        // Fuel logs
        Schema::create('vehicle_fuel_logs', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('vehicle_id');
            $table->uuid('driver_id');
            $table->decimal('liters', 8, 2);
            $table->decimal('price_per_liter', 10, 2);
            $table->decimal('total_cost', 12, 2);
            $table->string('fuel_type', 50)->default('pertamax');
            $table->decimal('km_reading', 10, 1)->nullable();
            $table->text('receipt_photo_path')->nullable();
            $table->text('speedometer_photo_path')->nullable();
            $table->string('station_name', 255)->nullable();
            $table->string('validation_status', 30)->default('pending'); // pending, validated, rejected
            $table->uuid('validated_by')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('vehicle_id')->references('id')->on('vehicles');
            $table->foreign('driver_id')->references('id')->on('users');
            $table->foreign('validated_by')->references('id')->on('users');
        });

        // Inspection master (checklist items)
        Schema::create('vehicle_inspection_master', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('category', 100); // exterior, interior, engine, safety, documents
            $table->string('item_name', 255);
            $table->string('check_type', 30)->default('boolean'); // boolean, rating, text
            $table->integer('sort_order')->default(0);
            $table->boolean('is_critical')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Inspection results (header)
        Schema::create('vehicle_inspections', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('vehicle_id');
            $table->uuid('driver_id');
            $table->string('inspection_type', 30); // pre_trip, post_trip
            $table->decimal('km_reading', 10, 1)->nullable();
            $table->integer('total_items')->default(0);
            $table->integer('passed_items')->default(0);
            $table->integer('failed_items')->default(0);
            $table->boolean('overall_passed')->default(true);
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('vehicle_id')->references('id')->on('vehicles');
            $table->foreign('driver_id')->references('id')->on('users');
        });

        // Inspection items (detail)
        Schema::create('vehicle_inspection_items', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('inspection_id');
            $table->uuid('master_item_id');
            $table->boolean('is_passed')->default(true);
            $table->string('value', 255)->nullable(); // for rating/text type
            $table->text('photo_path')->nullable();
            $table->text('notes')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('inspection_id')->references('id')->on('vehicle_inspections')->onDelete('cascade');
            $table->foreign('master_item_id')->references('id')->on('vehicle_inspection_master');
        });

        // Maintenance requests
        Schema::create('vehicle_maintenance_requests', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('vehicle_id');
            $table->uuid('reported_by');
            $table->string('category', 100); // engine, brake, tire, body, electrical, other
            $table->string('priority', 30)->default('medium'); // low, medium, high, critical
            $table->text('description');
            $table->text('photo_path')->nullable();
            $table->string('status', 30)->default('reported'); // reported, acknowledged, in_progress, completed, deferred
            $table->uuid('assigned_to')->nullable();
            $table->timestamp('acknowledged_at')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->decimal('cost', 12, 2)->nullable();
            $table->text('resolution_notes')->nullable();
            $table->timestamps();

            $table->foreign('vehicle_id')->references('id')->on('vehicles');
            $table->foreign('reported_by')->references('id')->on('users');
            $table->foreign('assigned_to')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vehicle_maintenance_requests');
        Schema::dropIfExists('vehicle_inspection_items');
        Schema::dropIfExists('vehicle_inspections');
        Schema::dropIfExists('vehicle_inspection_master');
        Schema::dropIfExists('vehicle_fuel_logs');
        Schema::dropIfExists('vehicle_km_logs');
    }
};
