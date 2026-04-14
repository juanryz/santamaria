<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_checklists', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->string('religion', 50);
            $table->string('item_name', 255);
            $table->string('item_category', 100);
            $table->boolean('is_checked')->default(false);
            $table->uuid('checked_by')->nullable();
            $table->timestamp('checked_at')->nullable();
            $table->string('target_role', 50);
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders')->onDelete('cascade');
            $table->foreign('checked_by')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_checklists');
    }
};
