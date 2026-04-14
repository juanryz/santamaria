<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_consumable_lines', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('consumable_daily_id');
            $table->uuid('consumable_master_id');
            $table->integer('qty')->default(0);
            $table->string('notes', 255)->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('consumable_daily_id')->references('id')->on('order_consumables_daily')->onDelete('cascade');
            $table->foreign('consumable_master_id')->references('id')->on('consumable_master');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_consumable_lines');
    }
};
