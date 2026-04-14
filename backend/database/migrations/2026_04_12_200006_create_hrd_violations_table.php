<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('hrd_violations', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));

            $table->uuid('violated_by');
            $table->foreign('violated_by')->references('id')->on('users');

            $table->uuid('order_id')->nullable();
            $table->foreign('order_id')->references('id')->on('orders');

            $table->enum('violation_type', [
                'driver_overtime',
                'so_late_processing',
                'vendor_no_show',
                'vendor_repeated_reject',
                'field_team_absent',
                'late_bukti_upload',
                'late_payment_processing',
                'late_field_team_payment',
                'other',
            ]);

            $table->text('description');
            $table->decimal('threshold_value', 10, 2)->nullable();
            $table->decimal('actual_value', 10, 2)->nullable();
            $table->enum('severity', ['low', 'medium', 'high']);
            $table->text('hrd_notes')->nullable();
            $table->enum('status', ['new', 'acknowledged', 'resolved', 'escalated'])->default('new');
            $table->uuid('acknowledged_by')->nullable();
            $table->foreign('acknowledged_by')->references('id')->on('users');
            $table->timestamp('acknowledged_at')->nullable();
            $table->uuid('resolved_by')->nullable();
            $table->foreign('resolved_by')->references('id')->on('users');
            $table->timestamp('resolved_at')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('hrd_violations');
    }
};
