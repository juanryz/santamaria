<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('obituaries', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('slug')->unique();
            $table->string('deceased_name');
            $table->string('deceased_nickname')->nullable();
            $table->date('deceased_dob')->nullable();
            $table->date('deceased_dod');
            $table->string('deceased_place_of_birth')->nullable();
            $table->string('deceased_religion')->nullable();
            $table->string('deceased_photo_path')->nullable();
            $table->unsignedInteger('deceased_age')->nullable();
            $table->string('family_contact_name')->nullable();
            $table->string('family_contact_phone')->nullable();
            $table->text('family_message')->nullable();
            $table->text('survived_by')->nullable();
            $table->string('funeral_location')->nullable();
            $table->timestamp('funeral_datetime')->nullable();
            $table->string('funeral_address')->nullable();
            $table->string('cemetery_name')->nullable();
            $table->string('prayer_location')->nullable();
            $table->timestamp('prayer_datetime')->nullable();
            $table->text('prayer_notes')->nullable();
            $table->enum('status', ['draft', 'published', 'archived'])->default('draft');
            $table->timestamp('published_at')->nullable();
            $table->boolean('is_featured')->default(false);
            $table->unsignedInteger('view_count')->default(0);
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();
            $table->index(['status', 'published_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('obituaries');
    }
};
