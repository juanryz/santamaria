<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO $$ BEGIN CREATE TYPE kpi_calculation_type AS ENUM ('average','percentage','count','inverse_count','sum'); EXCEPTION WHEN duplicate_object THEN null; END $$");
        DB::statement("DO $$ BEGIN CREATE TYPE kpi_target_direction AS ENUM ('lower_is_better','higher_is_better'); EXCEPTION WHEN duplicate_object THEN null; END $$");

        Schema::create('kpi_metric_master', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('metric_code', 50)->unique();
            $table->string('metric_name', 255);
            $table->text('description')->nullable();
            $table->string('applicable_role', 50);
            $table->string('data_source', 100);
            $table->text('calculation_query');
            $table->string('unit', 50);
            $table->decimal('target_value', 10, 2);
            $table->decimal('weight', 5, 2)->default(10);
            $table->integer('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        DB::statement("ALTER TABLE kpi_metric_master ADD COLUMN calculation_type kpi_calculation_type NOT NULL");
        DB::statement("ALTER TABLE kpi_metric_master ADD COLUMN target_direction kpi_target_direction NOT NULL");
    }

    public function down(): void
    {
        Schema::dropIfExists('kpi_metric_master');
        DB::statement("DROP TYPE IF EXISTS kpi_calculation_type");
        DB::statement("DROP TYPE IF EXISTS kpi_target_direction");
    }
};
