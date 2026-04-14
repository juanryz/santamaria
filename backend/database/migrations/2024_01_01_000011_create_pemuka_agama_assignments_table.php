<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pemuka_agama_assignments', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->uuid('pemuka_agama_id');
            $table->integer('attempt_number')->default(1);
            $table->timestamp('notified_at');
            $table->enum('response', ['pending', 'confirmed', 'rejected', 'expired'])->default('pending');
            $table->timestamp('responded_at')->nullable();
            $table->timestamp('expiry_at');
            $table->timestamp('created_at')->nullable();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('pemuka_agama_id')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pemuka_agama_assignments');
    }
};
