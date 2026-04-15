<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        // Konfigurasi upah per shift (dinamis, bisa diubah admin)
        Schema::create('tukang_jaga_wage_configs', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(\DB::raw('gen_random_uuid()'));
            $table->string('label', 100);              // e.g. "Shift Malam Reguler"
            $table->string('shift_type', 50);          // 'pagi','siang','malam','full_day'
            $table->decimal('rate', 12, 2);            // upah per shift
            $table->string('currency', 10)->default('IDR');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Shift tukang jaga per order
        Schema::create('tukang_jaga_shifts', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(\DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->integer('shift_number');           // 1, 2, 3...
            $table->string('shift_type', 50);          // 'pagi','siang','malam','full_day'
            $table->timestamp('scheduled_start');
            $table->timestamp('scheduled_end');
            $table->uuid('assigned_to')->nullable();   // FK ke users (role: tukang_jaga)
            $table->timestamp('checkin_at')->nullable();
            $table->timestamp('checkout_at')->nullable();
            $table->uuid('checkin_verified_by')->nullable(); // SO/admin yang verifikasi
            $table->string('status', 30)->default('scheduled'); // scheduled,active,completed,missed
            $table->uuid('wage_config_id')->nullable();
            $table->decimal('wage_amount', 12, 2)->nullable(); // dihitung saat checkout
            $table->boolean('wage_paid')->default(false);
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders')->onDelete('cascade');
            $table->foreign('assigned_to')->references('id')->on('users');
            $table->foreign('checkin_verified_by')->references('id')->on('users');
            $table->foreign('wage_config_id')->references('id')->on('tukang_jaga_wage_configs');
        });

        // Item tambahan yang diterima tukang jaga dari driver/gudang/laviore
        Schema::create('tukang_jaga_item_deliveries', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(\DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->uuid('shift_id');                  // shift aktif saat menerima
            $table->uuid('delivered_by');              // driver/gudang/laviore user
            $table->string('delivered_by_role', 50);
            $table->uuid('received_by')->nullable();   // tukang_jaga yang menerima
            $table->string('status', 30)->default('delivered');
            // delivered → received_by_jaga → confirmed_by_family
            $table->timestamp('delivered_at')->nullable();
            $table->timestamp('received_at')->nullable();
            $table->timestamp('family_confirmed_at')->nullable();
            $table->uuid('family_confirmed_by')->nullable(); // consumer user
            $table->text('delivery_notes')->nullable();
            $table->text('family_notes')->nullable();
            $table->string('delivery_photo_path')->nullable(); // foto bukti pengiriman
            $table->string('receipt_photo_path')->nullable();  // foto setelah diterima jaga
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders')->onDelete('cascade');
            $table->foreign('shift_id')->references('id')->on('tukang_jaga_shifts');
            $table->foreign('delivered_by')->references('id')->on('users');
            $table->foreign('received_by')->references('id')->on('users');
            $table->foreign('family_confirmed_by')->references('id')->on('users');
        });

        // Item lines per pengiriman
        Schema::create('tukang_jaga_delivery_items', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(\DB::raw('gen_random_uuid()'));
            $table->uuid('delivery_id');
            $table->string('item_name', 255);
            $table->integer('quantity')->default(1);
            $table->string('unit', 50)->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('delivery_id')->references('id')->on('tukang_jaga_item_deliveries')->onDelete('cascade');
        });
    }

    public function down(): void {
        Schema::dropIfExists('tukang_jaga_delivery_items');
        Schema::dropIfExists('tukang_jaga_item_deliveries');
        Schema::dropIfExists('tukang_jaga_shifts');
        Schema::dropIfExists('tukang_jaga_wage_configs');
    }
};
