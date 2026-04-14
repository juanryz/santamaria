<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('equipment_master', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('category', 100);
            $table->string('sub_category', 100)->nullable();
            $table->string('item_name', 255);
            $table->string('item_code', 50)->unique()->nullable();
            $table->integer('default_qty')->default(1);
            $table->string('unit', 50)->default('pcs');
            $table->boolean('is_active')->default(true);
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('equipment_master');
    }
};
