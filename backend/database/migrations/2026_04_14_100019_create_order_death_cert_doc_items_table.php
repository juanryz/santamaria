<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_death_cert_doc_items', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('death_cert_id');
            $table->uuid('doc_master_id');
            $table->boolean('diterima_sm')->default(false);
            $table->boolean('diterima_keluarga')->default(false);
            $table->string('notes', 255)->nullable();
            $table->timestamps();

            $table->foreign('death_cert_id')->references('id')->on('order_death_certificate_docs')->onDelete('cascade');
            $table->foreign('doc_master_id')->references('id')->on('death_cert_doc_master');
            $table->unique(['death_cert_id', 'doc_master_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_death_cert_doc_items');
    }
};
