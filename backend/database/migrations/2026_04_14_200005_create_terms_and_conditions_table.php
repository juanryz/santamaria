<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('terms_and_conditions', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('version', 20)->unique();
            $table->string('title', 255);
            $table->text('content');
            $table->date('effective_date');
            $table->boolean('is_current')->default(false);
            $table->uuid('created_by')->nullable();
            $table->timestamps();

            $table->foreign('created_by')->references('id')->on('users');
        });

        // Order trip template
        Schema::create('order_trip_templates', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('package_id');
            $table->uuid('leg_master_id');
            $table->smallInteger('leg_sequence');
            $table->string('default_origin_label', 255);
            $table->string('default_destination_label', 255);
            $table->boolean('is_optional')->default(false);
            $table->text('notes')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('package_id')->references('id')->on('packages');
            $table->foreign('leg_master_id')->references('id')->on('trip_leg_master');
            $table->unique(['package_id', 'leg_sequence']);
        });

        // Order vendor assignments (unified)
        Schema::create('order_vendor_assignments', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->uuid('vendor_role_id');
            $table->uuid('user_id')->nullable();
            $table->string('ext_name', 255)->nullable();
            $table->string('ext_phone', 30)->nullable();
            $table->string('ext_whatsapp', 30)->nullable();
            $table->string('ext_email', 255)->nullable();
            $table->string('ext_organization', 255)->nullable();
            $table->text('ext_notes')->nullable();
            $table->timestamp('assigned_at')->useCurrent();
            $table->uuid('assigned_by')->nullable();
            $table->boolean('requested_by_consumer')->default(false);
            $table->date('scheduled_date')->nullable();
            $table->time('scheduled_time')->nullable();
            $table->string('status', 50)->default('assigned');
            $table->timestamp('confirmed_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('vendor_role_id')->references('id')->on('vendor_role_master');
            $table->foreign('user_id')->references('id')->on('users');
            $table->foreign('assigned_by')->references('id')->on('users');
        });

        DB::statement("ALTER TABLE order_vendor_assignments ADD COLUMN source VARCHAR(50) NOT NULL DEFAULT 'internal'");
    }

    public function down(): void
    {
        Schema::dropIfExists('order_vendor_assignments');
        Schema::dropIfExists('order_trip_templates');
        Schema::dropIfExists('terms_and_conditions');
    }
};
