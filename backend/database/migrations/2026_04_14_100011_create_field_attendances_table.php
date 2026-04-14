<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO $$ BEGIN CREATE TYPE attendance_status AS ENUM ('scheduled','present','absent','late'); EXCEPTION WHEN duplicate_object THEN null; END $$");

        Schema::create('field_attendances', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->uuid('user_id');
            $table->string('role', 50);
            $table->date('attendance_date');
            $table->string('kegiatan', 255);
            $table->time('scheduled_jam')->nullable();
            $table->timestamp('arrived_at')->nullable();
            $table->timestamp('departed_at')->nullable();
            $table->boolean('pic_confirmed')->default(false);
            $table->uuid('pic_confirmed_by')->nullable();
            $table->timestamp('pic_confirmed_at')->nullable();
            $table->text('pic_signature_path')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('user_id')->references('id')->on('users');
            $table->foreign('pic_confirmed_by')->references('id')->on('users');
        });

        DB::statement("ALTER TABLE field_attendances ADD COLUMN status attendance_status NOT NULL DEFAULT 'scheduled'");
    }

    public function down(): void
    {
        Schema::dropIfExists('field_attendances');
        DB::statement("DROP TYPE IF EXISTS attendance_status");
    }
};
