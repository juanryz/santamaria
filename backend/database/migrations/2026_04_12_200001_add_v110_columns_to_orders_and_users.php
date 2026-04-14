<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Add so_channel to users
        Schema::table('users', function (Blueprint $table) {
            $table->enum('so_channel', ['field', 'office'])->nullable()->after('role');
        });

        // Add HRD role to users (PostgreSQL requires dropping and recreating the enum)
        DB::statement("ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check");
        DB::statement("ALTER TABLE users ALTER COLUMN role TYPE VARCHAR(50)");

        // Add v1.9 + v1.10 columns to orders
        Schema::table('orders', function (Blueprint $table) {
            $table->enum('created_by_so_channel', ['field', 'office', 'consumer_self'])->default('consumer_self')->after('so_user_id');
            $table->decimal('estimated_duration_hours', 4, 1)->default(3.0)->after('scheduled_at');

            // Update status enum — done via raw SQL below

            // Payment proof from consumer
            $table->text('payment_proof_path')->nullable()->after('payment_notes');
            $table->timestamp('payment_proof_uploaded_at')->nullable()->after('payment_proof_path');
            $table->uuid('payment_verified_by')->nullable()->after('payment_proof_uploaded_at');
            $table->foreign('payment_verified_by')->references('id')->on('users');

            // Auto-complete tracking
            $table->timestamp('auto_completed_at')->nullable()->after('completed_at');
            $table->enum('completion_method', ['auto_time', 'manual'])->nullable()->default('auto_time')->after('auto_completed_at');

            // Needs restock flag
            $table->boolean('needs_restock')->default(false)->after('gudang_status');
        });

        // Update orders.status enum to v1.9 (PostgreSQL)
        DB::statement("ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check");
        DB::statement("ALTER TABLE orders ALTER COLUMN status TYPE VARCHAR(50)");
        DB::statement("ALTER TABLE orders ADD CONSTRAINT orders_status_check CHECK (status IN ('pending','so_review','admin_review','confirmed','approved','in_progress','completed','cancelled'))");
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['payment_verified_by']);
            $table->dropColumn([
                'created_by_so_channel',
                'estimated_duration_hours',
                'payment_proof_path',
                'payment_proof_uploaded_at',
                'payment_verified_by',
                'auto_completed_at',
                'completion_method',
                'needs_restock',
            ]);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('so_channel');
        });
    }
};
