<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vendor_performance', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('vendor_id');
            $table->integer('period_month');
            $table->integer('period_year');
            $table->integer('total_assignments')->default(0);
            $table->integer('confirmed_count')->default(0);
            $table->integer('rejected_count')->default(0);
            $table->integer('expired_count')->default(0);
            $table->decimal('avg_response_minutes', 8, 2)->nullable();
            $table->decimal('performance_score', 5, 2)->nullable();
            $table->timestamps();

            $table->foreign('vendor_id')->references('id')->on('users');
            $table->unique(['vendor_id', 'period_month', 'period_year']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vendor_performance');
    }
};
