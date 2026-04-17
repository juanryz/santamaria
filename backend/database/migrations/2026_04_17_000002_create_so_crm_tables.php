<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('so_prospects', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('so_user_id');
            $table->string('name');
            $table->string('phone', 30)->nullable();
            $table->text('address')->nullable();
            $table->string('source', 100)->nullable(); // referral, walk_in, rs, online, other
            $table->string('status', 50)->default('new'); // new, contacted, interested, converted, lost
            $table->text('notes')->nullable();
            $table->date('follow_up_date')->nullable();
            $table->uuid('converted_order_id')->nullable();
            $table->timestamps();

            $table->foreign('so_user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('converted_order_id')->references('id')->on('orders')->onDelete('set null');
            $table->index(['so_user_id', 'status']);
            $table->index('follow_up_date');
        });

        Schema::create('so_visit_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('so_user_id');
            $table->uuid('prospect_id')->nullable();
            $table->uuid('order_id')->nullable();
            $table->string('location');
            $table->string('purpose'); // prospek, follow_up, order_coordination, rumah_duka_visit
            $table->text('notes')->nullable();
            $table->date('visit_date');
            $table->uuid('photo_evidence_id')->nullable();
            $table->timestamps();

            $table->foreign('so_user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('prospect_id')->references('id')->on('so_prospects')->onDelete('set null');
            $table->foreign('order_id')->references('id')->on('orders')->onDelete('set null');
            $table->foreign('photo_evidence_id')->references('id')->on('photo_evidences')->onDelete('set null');
            $table->index(['so_user_id', 'visit_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('so_visit_logs');
        Schema::dropIfExists('so_prospects');
    }
};
