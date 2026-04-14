<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use App\Models\Order;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('order_number', 50)->unique();
            $table->enum('status', [
                Order::STATUS_PENDING,
                Order::STATUS_SO_REVIEW,
                Order::STATUS_ADMIN_REVIEW,
                Order::STATUS_APPROVED,
                Order::STATUS_IN_PROGRESS,
                Order::STATUS_COMPLETED,
                Order::STATUS_CANCELLED
            ])->default(Order::STATUS_PENDING);

            // Data Penanggung Jawab
            $table->uuid('pic_user_id');
            $table->string('pic_name', 255);
            $table->string('pic_phone', 20);
            $table->enum('pic_relation', ['anak', 'suami_istri', 'orang_tua', 'saudara', 'lainnya']);
            $table->text('pic_address');

            // Data Almarhum
            $table->string('deceased_name', 255);
            $table->date('deceased_dob')->nullable();
            $table->date('deceased_dod');
            $table->enum('deceased_religion', ['islam', 'kristen', 'katolik', 'hindu', 'buddha', 'konghucu']);
            $table->text('pickup_address');
            $table->decimal('pickup_lat', 10, 8)->nullable();
            $table->decimal('pickup_lng', 11, 8)->nullable();
            $table->text('destination_address');
            $table->decimal('destination_lat', 10, 8)->nullable();
            $table->decimal('destination_lng', 11, 8)->nullable();
            $table->text('special_notes')->nullable();
            $table->integer('estimated_guests')->nullable();

            // Data Paket
            $table->uuid('package_id')->nullable();
            $table->string('custom_package_name', 255)->nullable();
            $table->decimal('final_price', 15, 2)->nullable();
            $table->text('so_notes')->nullable();
            $table->uuid('so_user_id')->nullable();
            $table->timestamp('so_submitted_at')->nullable();

            // Data Jadwal & Logistik
            $table->timestamp('scheduled_at')->nullable();
            $table->uuid('driver_id')->nullable();
            $table->uuid('vehicle_id')->nullable();
            $table->text('admin_notes')->nullable();
            $table->uuid('admin_user_id')->nullable();
            $table->timestamp('approved_at')->nullable();

            // Status per Departemen
            $table->enum('gudang_status', ['pending', 'in_progress', 'ready', 'done'])->default('pending');
            $table->timestamp('gudang_confirmed_at')->nullable();
            
            $table->enum('driver_status', ['pending', 'on_the_way', 'arrived_pickup', 'arrived_destination', 'done'])->default('pending');
            $table->timestamp('driver_departed_at')->nullable();
            $table->timestamp('driver_arrived_pickup_at')->nullable();
            $table->timestamp('driver_arrived_destination_at')->nullable();
            
            $table->enum('dekor_status', ['pending', 'confirmed', 'done'])->default('pending');
            $table->timestamp('dekor_confirmed_at')->nullable();
            
            $table->enum('konsumsi_status', ['pending', 'confirmed', 'done'])->default('pending');
            $table->timestamp('konsumsi_confirmed_at')->nullable();
            
            $table->enum('pemuka_agama_status', ['pending', 'finding', 'confirmed', 'not_available'])->default('pending');
            $table->uuid('pemuka_agama_user_id')->nullable();
            $table->timestamp('pemuka_agama_confirmed_at')->nullable();

            // Payment
            $table->enum('payment_status', [
                Order::PAYMENT_STATUS_UNPAID,
                Order::PAYMENT_STATUS_PARTIAL,
                Order::PAYMENT_STATUS_PAID,
                Order::PAYMENT_STATUS_PROOF_UPLOADED,
                Order::PAYMENT_STATUS_PROOF_REJECTED,
            ])->default(Order::PAYMENT_STATUS_UNPAID);
            $table->decimal('payment_amount', 15, 2)->nullable();
            $table->text('payment_notes')->nullable();
            $table->timestamp('payment_updated_at')->nullable();
            $table->uuid('payment_updated_by')->nullable();

            // Dokumen & Media
            $table->text('invoice_path')->nullable();
            $table->text('akta_path')->nullable();
            $table->text('duka_text')->nullable();

            // Metadata
            $table->bigInteger('storage_used_bytes')->default(0);
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->text('cancelled_reason')->nullable();
            $table->timestamps();

            // Foreign keys
            $table->foreign('pic_user_id')->references('id')->on('users');
            $table->foreign('package_id')->references('id')->on('packages');
            $table->foreign('so_user_id')->references('id')->on('users');
            $table->foreign('driver_id')->references('id')->on('users');
            $table->foreign('vehicle_id')->references('id')->on('vehicles');
            $table->foreign('admin_user_id')->references('id')->on('users');
            $table->foreign('pemuka_agama_user_id')->references('id')->on('users');
            $table->foreign('payment_updated_by')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
