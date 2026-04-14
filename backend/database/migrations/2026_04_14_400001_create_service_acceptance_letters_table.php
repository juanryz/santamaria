<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('service_acceptance_letters', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id')->unique();
            $table->string('letter_number', 50)->unique()->nullable();

            // Status: draft → pending_signature → signed → confirmed
            $table->string('status', 30)->default('draft');

            // Section 1: Penanggung Jawab
            $table->string('pj_nama', 255);
            $table->text('pj_alamat')->nullable();
            $table->string('pj_no_telp', 30)->nullable();
            $table->string('pj_no_ktp', 30)->nullable();
            $table->string('pj_hubungan', 100)->nullable();

            // Section 2: Almarhum
            $table->string('almarhum_nama', 255);
            $table->date('almarhum_tgl_lahir')->nullable();
            $table->date('almarhum_tgl_wafat')->nullable();
            $table->string('almarhum_agama', 50)->nullable();
            $table->text('almarhum_alamat_terakhir')->nullable();

            // Section 3: Detail Layanan
            $table->string('paket_nama', 255)->nullable();
            $table->decimal('paket_harga', 15, 2)->nullable();
            $table->text('layanan_tambahan')->nullable();
            $table->decimal('total_biaya', 15, 2)->nullable();

            // Section 4: Lokasi & Jadwal
            $table->text('lokasi_prosesi')->nullable();
            $table->text('lokasi_pemakaman')->nullable();
            $table->timestamp('jadwal_mulai')->nullable();
            $table->decimal('estimasi_durasi_jam', 4, 1)->nullable();

            // Section 5: Terms version
            $table->string('terms_version', 20)->nullable();

            // Section 6: Signatures
            // Pihak Pertama (PJ / Keluarga)
            $table->timestamp('pj_signed_at')->nullable();
            $table->text('pj_signature_path')->nullable();

            // Saksi (optional)
            $table->string('saksi_nama', 255)->nullable();
            $table->string('saksi_no_ktp', 30)->nullable();
            $table->timestamp('saksi_signed_at')->nullable();
            $table->text('saksi_signature_path')->nullable();

            // Pihak Kedua (SM Officer)
            $table->uuid('sm_officer_id')->nullable();
            $table->string('sm_officer_nama', 255)->nullable();
            $table->timestamp('sm_signed_at')->nullable();
            $table->text('sm_signature_path')->nullable();

            // Meta
            $table->uuid('created_by')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('sm_officer_id')->references('id')->on('users');
            $table->foreign('created_by')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_acceptance_letters');
    }
};
