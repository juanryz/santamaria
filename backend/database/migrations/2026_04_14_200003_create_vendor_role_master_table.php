<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO $$ BEGIN CREATE TYPE vendor_role_category AS ENUM ('religious','documentation','decoration','catering','music','other'); EXCEPTION WHEN duplicate_object THEN null; END $$");

        Schema::create('vendor_role_master', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('role_code', 50)->unique();
            $table->string('role_name', 255);
            $table->text('description')->nullable();
            $table->string('app_role', 50)->nullable();
            $table->boolean('is_default_in_package')->default(false);
            $table->smallInteger('max_per_order')->nullable();
            $table->boolean('requires_attendance')->default(true);
            $table->boolean('requires_bukti_foto')->default(false);
            $table->string('icon', 50)->nullable();
            $table->integer('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        DB::statement("ALTER TABLE vendor_role_master ADD COLUMN category vendor_role_category NOT NULL DEFAULT 'other'");
    }

    public function down(): void
    {
        Schema::dropIfExists('vendor_role_master');
        DB::statement("DROP TYPE IF EXISTS vendor_role_category");
    }
};
