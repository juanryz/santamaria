<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('extra_approval_lines', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('approval_id');
            $table->smallInteger('line_number');
            $table->string('keterangan', 255);
            $table->decimal('biaya', 15, 2)->default(0);
            $table->string('notes', 255)->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('approval_id')->references('id')->on('order_extra_approvals')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('extra_approval_lines');
    }
};
