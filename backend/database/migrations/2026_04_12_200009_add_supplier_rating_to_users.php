<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->decimal('supplier_rating_avg', 3, 2)->default(0)->after('is_verified_supplier');
            $table->integer('supplier_rating_count')->default(0)->after('supplier_rating_avg');
        });

        Schema::create('supplier_ratings', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(\Illuminate\Support\Facades\DB::raw('gen_random_uuid()'));
            $table->uuid('supplier_id');
            $table->foreign('supplier_id')->references('id')->on('users');
            $table->uuid('procurement_request_id');
            $table->foreign('procurement_request_id')->references('id')->on('procurement_requests');
            $table->uuid('rated_by');
            $table->foreign('rated_by')->references('id')->on('users');
            $table->tinyInteger('rating');  // 1-5
            $table->text('review')->nullable();
            $table->timestamps();
            $table->unique(['supplier_id', 'procurement_request_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('supplier_ratings');
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['supplier_rating_avg', 'supplier_rating_count']);
        });
    }
};
