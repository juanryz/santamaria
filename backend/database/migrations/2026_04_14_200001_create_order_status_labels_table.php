<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_status_labels', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('status_code', 50)->unique();
            $table->string('consumer_label', 255);
            $table->text('consumer_description')->nullable();
            $table->string('internal_label', 255);
            $table->string('icon', 50);
            $table->string('color', 20);
            $table->smallInteger('sort_order');
            $table->boolean('show_to_consumer')->default(true);
            $table->boolean('show_map_tracking')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_status_labels');
    }
};
