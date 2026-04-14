<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_gallery_links', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->uuid('uploaded_by');
            $table->string('title', 255);
            $table->text('drive_url');
            $table->text('description')->nullable();
            $table->string('link_type', 50)->default('google_drive'); // google_drive, other
            $table->boolean('is_visible_consumer')->default(true);
            $table->boolean('is_visible_so')->default(true);
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('uploaded_by')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_gallery_links');
    }
};
