<?php

use App\Enums\UserRole;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('name', 255);
            $table->string('phone', 20)->unique();
            $table->string('email', 255)->unique()->nullable();
            $table->enum('role', UserRole::values());
            $table->string('pin', 255)->nullable();
            $table->string('password', 255)->nullable();
            $table->boolean('is_viewer')->default(false);
            $table->boolean('is_active')->default(true);
            $table->text('device_fcm_token')->nullable();
            $table->text('avatar_url')->nullable();
            $table->string('religion', 50)->nullable();
            $table->decimal('location_lat', 10, 8)->nullable();
            $table->decimal('location_lng', 11, 8)->nullable();
            $table->uuid('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::table('users', function (Blueprint $table) {
            $table->foreign('created_by')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
