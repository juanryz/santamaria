<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('order_photos', function (Blueprint $table) {
            // Allow file_path / file_size_bytes / file_type to be null
            // (drive link records don't have a physical file)
            $table->text('file_path')->nullable()->change();
            $table->bigInteger('file_size_bytes')->nullable()->change();
            $table->string('file_type', 50)->nullable()->change();

            // Who uploaded: consumer (self-upload) or staff (CRM/admin post-event)
            $table->string('source', 20)->default('consumer')->after('category');

            // Optional Google Drive / YouTube link instead of a physical file
            $table->text('drive_link')->nullable()->after('source');

            // Caption for staff uploads
            $table->string('caption', 255)->nullable()->after('drive_link');
        });
    }

    public function down(): void
    {
        Schema::table('order_photos', function (Blueprint $table) {
            $table->dropColumn(['source', 'drive_link', 'caption']);
            $table->text('file_path')->nullable(false)->change();
            $table->bigInteger('file_size_bytes')->nullable(false)->change();
            $table->string('file_type', 50)->nullable(false)->change();
        });
    }
};
