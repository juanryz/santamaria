<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_add_ons', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->uuid('add_on_service_id');
            $table->decimal('price_at_time', 15, 2)->default(0);
            $table->integer('quantity')->default(1);
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders')->onDelete('cascade');
            $table->foreign('add_on_service_id')->references('id')->on('add_on_services')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_add_ons');
    }
};
