<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO $$ BEGIN CREATE TYPE trip_leg_category AS ENUM ('logistics','transport_jenazah','return','other'); EXCEPTION WHEN duplicate_object THEN null; END $$");

        Schema::create('trip_leg_master', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('leg_code', 50)->unique();
            $table->string('leg_name', 255);
            $table->text('description')->nullable();
            $table->boolean('requires_proof_photo')->default(true);
            $table->string('triggers_gate', 100)->nullable();
            $table->string('icon', 50)->nullable();
            $table->integer('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        DB::statement("ALTER TABLE trip_leg_master ADD COLUMN category trip_leg_category NOT NULL DEFAULT 'other'");
    }

    public function down(): void
    {
        Schema::dropIfExists('trip_leg_master');
        DB::statement("DROP TYPE IF EXISTS trip_leg_category");
    }
};
