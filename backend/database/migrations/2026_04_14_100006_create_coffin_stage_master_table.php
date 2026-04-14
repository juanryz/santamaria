<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('coffin_stage_master', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('finishing_type', 50);
            $table->smallInteger('stage_number');
            $table->string('stage_name', 100);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['finishing_type', 'stage_number']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('coffin_stage_master');
    }
};
