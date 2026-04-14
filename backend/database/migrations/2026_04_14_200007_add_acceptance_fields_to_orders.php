<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->timestamp('acceptance_signed_at')->nullable();
            $table->string('acceptance_signed_by_name', 255)->nullable();
            $table->string('acceptance_signed_relation', 100)->nullable();
            $table->text('acceptance_signature_path')->nullable();
            $table->string('acceptance_terms_version', 20)->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn([
                'acceptance_signed_at', 'acceptance_signed_by_name',
                'acceptance_signed_relation', 'acceptance_signature_path',
                'acceptance_terms_version',
            ]);
        });
    }
};
