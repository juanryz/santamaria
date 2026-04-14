<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO $$ BEGIN CREATE TYPE kpi_trend AS ENUM ('up','down','stable'); EXCEPTION WHEN duplicate_object THEN null; END $$");

        Schema::create('kpi_user_summary', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('period_id');
            $table->uuid('user_id');
            $table->decimal('total_score', 5, 2);
            $table->string('grade', 10);
            $table->smallInteger('rank_in_role')->nullable();
            $table->smallInteger('total_in_role')->nullable();
            $table->decimal('prev_total_score', 5, 2)->nullable();
            $table->timestamp('calculated_at');
            $table->timestamps();

            $table->foreign('period_id')->references('id')->on('kpi_periods');
            $table->foreign('user_id')->references('id')->on('users');
            $table->unique(['period_id', 'user_id']);
        });

        DB::statement("ALTER TABLE kpi_user_summary ADD COLUMN trend kpi_trend NULL");
    }

    public function down(): void
    {
        Schema::dropIfExists('kpi_user_summary');
        DB::statement("DROP TYPE IF EXISTS kpi_trend");
    }
};
