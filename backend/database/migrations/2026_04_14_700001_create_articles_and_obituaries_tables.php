<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ── Tabel articles (Blog/Artikel Publik) ──────────────────────────
        Schema::create('articles', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('title');
            $table->string('slug')->unique();
            $table->text('excerpt')->nullable();
            $table->longText('body');
            $table->string('cover_image_path')->nullable();
            $table->string('category')->default('umum');
            $table->json('tags')->nullable();
            $table->enum('status', ['draft', 'published', 'archived'])->default('draft');
            $table->timestamp('published_at')->nullable();
            $table->uuid('author_id');
            $table->foreign('author_id')->references('id')->on('users')->onDelete('cascade');
            $table->boolean('is_featured')->default(false);
            $table->unsignedInteger('view_count')->default(0);
            $table->string('meta_title')->nullable();
            $table->string('meta_description')->nullable();
            $table->softDeletes();
            $table->timestamps();

            $table->index(['status', 'published_at']);
            $table->index('category');
            $table->index('is_featured');
        });

        // ── Tabel obituaries (Berita Duka / Pengumuman Kematian Publik) ──
        Schema::create('obituaries', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('slug')->unique();

            // Data almarhum/almarhumah
            $table->string('deceased_name');
            $table->string('deceased_nickname')->nullable();
            $table->date('deceased_dob')->nullable();
            $table->date('deceased_dod');
            $table->string('deceased_place_of_birth')->nullable();
            $table->string('deceased_religion')->nullable();
            $table->string('deceased_photo_path')->nullable();
            $table->unsignedInteger('deceased_age')->nullable();

            // Info keluarga
            $table->string('family_contact_name')->nullable();
            $table->string('family_contact_phone')->nullable();
            $table->text('family_message')->nullable();
            $table->text('survived_by')->nullable(); // "Meninggalkan istri, 3 anak, 5 cucu..."

            // Info pemakaman
            $table->string('funeral_location')->nullable();
            $table->timestamp('funeral_datetime')->nullable();
            $table->string('funeral_address')->nullable();
            $table->string('cemetery_name')->nullable();

            // Info doa/upacara
            $table->string('prayer_location')->nullable();
            $table->timestamp('prayer_datetime')->nullable();
            $table->text('prayer_notes')->nullable();

            // Relasi ke order (opsional — bisa standalone)
            $table->uuid('order_id')->nullable();
            $table->foreign('order_id')->references('id')->on('orders')->onDelete('set null');

            // Admin
            $table->uuid('created_by');
            $table->foreign('created_by')->references('id')->on('users')->onDelete('cascade');
            $table->enum('status', ['draft', 'published', 'archived'])->default('draft');
            $table->timestamp('published_at')->nullable();
            $table->boolean('is_featured')->default(false);
            $table->unsignedInteger('view_count')->default(0);

            // SEO
            $table->string('meta_title')->nullable();
            $table->string('meta_description')->nullable();

            $table->softDeletes();
            $table->timestamps();

            $table->index(['status', 'published_at']);
            $table->index('deceased_dod');
            $table->index('is_featured');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('obituaries');
        Schema::dropIfExists('articles');
    }
};
