<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('kpi_scores', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('period_id');
            $table->uuid('user_id');
            $table->uuid('metric_id');
            $table->decimal('actual_value', 10, 2);
            $table->decimal('target_value', 10, 2);
            $table->decimal('score', 5, 2);
            $table->decimal('weighted_score', 5, 2);
            $table->decimal('weight', 5, 2);
            $table->jsonb('calculation_detail')->nullable();
            $table->timestamp('calculated_at');
            $table->timestamps();

            $table->foreign('period_id')->references('id')->on('kpi_periods');
            $table->foreign('user_id')->references('id')->on('users');
            $table->foreign('metric_id')->references('id')->on('kpi_metric_master');
            $table->unique(['period_id', 'user_id', 'metric_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('kpi_scores');
    }
};
