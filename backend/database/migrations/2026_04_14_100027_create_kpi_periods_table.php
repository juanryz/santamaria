<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO $$ BEGIN CREATE TYPE kpi_period_type AS ENUM ('monthly','quarterly','yearly'); EXCEPTION WHEN duplicate_object THEN null; END $$");
        DB::statement("DO $$ BEGIN CREATE TYPE kpi_period_status AS ENUM ('open','calculating','closed'); EXCEPTION WHEN duplicate_object THEN null; END $$");

        Schema::create('kpi_periods', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('period_name', 100);
            $table->date('start_date');
            $table->date('end_date');
            $table->uuid('closed_by')->nullable();
            $table->timestamp('closed_at')->nullable();
            $table->timestamps();

            $table->foreign('closed_by')->references('id')->on('users');
        });

        DB::statement("ALTER TABLE kpi_periods ADD COLUMN period_type kpi_period_type NOT NULL DEFAULT 'monthly'");
        DB::statement("ALTER TABLE kpi_periods ADD COLUMN status kpi_period_status DEFAULT 'open'");
        DB::statement("ALTER TABLE kpi_periods ADD CONSTRAINT uq_kpi_period UNIQUE (period_type, start_date)");
    }

    public function down(): void
    {
        Schema::dropIfExists('kpi_periods');
        DB::statement("DROP TYPE IF EXISTS kpi_period_type");
        DB::statement("DROP TYPE IF EXISTS kpi_period_status");
    }
};
