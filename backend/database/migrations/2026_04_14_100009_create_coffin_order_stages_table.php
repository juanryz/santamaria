<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('coffin_order_stages', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('coffin_order_id');
            $table->uuid('stage_master_id');
            $table->smallInteger('stage_number');
            $table->string('stage_name', 100);
            $table->boolean('is_completed')->default(false);
            $table->timestamp('completed_at')->nullable();
            $table->string('completed_by_name', 255)->nullable();
            $table->text('notes')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('coffin_order_id')->references('id')->on('coffin_orders');
            $table->foreign('stage_master_id')->references('id')->on('coffin_stage_master');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('coffin_order_stages');
    }
};
