<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO $$ BEGIN CREATE TYPE wa_target_audience AS ENUM ('consumer','vendor_external','vendor_internal','supplier','other'); EXCEPTION WHEN duplicate_object THEN null; END $$");

        Schema::create('wa_message_templates', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('template_code', 50)->unique();
            $table->string('template_name', 255);
            $table->string('trigger_moment', 100);
            $table->text('message_template');
            $table->boolean('is_active')->default(true);
            $table->uuid('updated_by')->nullable();
            $table->timestamps();

            $table->foreign('updated_by')->references('id')->on('users');
        });

        DB::statement("ALTER TABLE wa_message_templates ADD COLUMN target_audience wa_target_audience NOT NULL DEFAULT 'consumer'");

        // Log table
        Schema::create('wa_message_logs', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('template_id');
            $table->uuid('order_id')->nullable();
            $table->uuid('sent_by');
            $table->string('recipient_phone', 30);
            $table->string('recipient_name', 255);
            $table->text('message_content');
            $table->timestamp('sent_at')->useCurrent();
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('template_id')->references('id')->on('wa_message_templates');
            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('sent_by')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wa_message_logs');
        Schema::dropIfExists('wa_message_templates');
        DB::statement("DROP TYPE IF EXISTS wa_target_audience");
    }
};
