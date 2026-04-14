<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('daily_reports', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->date('report_date')->unique();
            $table->integer('total_orders_today')->default(0);
            $table->integer('completed_orders')->default(0);
            $table->integer('pending_orders')->default(0);
            $table->decimal('total_revenue', 15, 2)->default(0);
            $table->decimal('total_paid', 15, 2)->default(0);
            $table->integer('anomalies_detected')->default(0);
            $table->text('ai_narrative')->nullable();
            $table->timestamp('sent_to_owner_at')->nullable();
            $table->timestamp('created_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('daily_reports');
    }
};
