<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_photos', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->uuid('uploaded_by');
            $table->text('file_path');
            $table->string('file_name', 255);
            $table->bigInteger('file_size_bytes');
            $table->string('file_type', 50);
            $table->enum('category', ['almarhum', 'dokumentasi', 'lapangan'])->default('almarhum');
            $table->timestamp('created_at');

            $table->foreign('order_id')->references('id')->on('orders')->onDelete('cascade');
            $table->foreign('uploaded_by')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_photos');
    }
};
