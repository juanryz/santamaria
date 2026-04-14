<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('coffin_qc_results', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('coffin_order_id');
            $table->uuid('criteria_master_id');
            $table->boolean('is_passed')->default(false);
            $table->string('notes', 255)->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('coffin_order_id')->references('id')->on('coffin_orders')->onDelete('cascade');
            $table->foreign('criteria_master_id')->references('id')->on('coffin_qc_criteria_master');
            $table->unique(['coffin_order_id', 'criteria_master_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('coffin_qc_results');
    }
};
