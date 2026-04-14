<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO $$ BEGIN CREATE TYPE equipment_item_status AS ENUM ('prepared','sent','received','partial_return','returned','missing'); EXCEPTION WHEN duplicate_object THEN null; END $$");

        Schema::create('order_equipment_items', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id')->nullable();
            $table->uuid('equipment_loan_id')->nullable();
            $table->uuid('equipment_item_id');
            $table->string('category', 100);
            $table->string('item_code', 50)->nullable();
            $table->text('item_description');
            $table->integer('qty_sent')->default(0);
            $table->integer('qty_received')->default(0);
            $table->integer('qty_returned')->default(0);
            $table->uuid('sent_by')->nullable();
            $table->timestamp('sent_at')->nullable();
            $table->string('received_by_family_name', 255)->nullable();
            $table->timestamp('received_by_family_at')->nullable();
            $table->uuid('received_by_pic_id')->nullable();
            $table->string('returned_by_family_name', 255)->nullable();
            $table->timestamp('returned_at')->nullable();
            $table->uuid('accepted_return_by')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('equipment_loan_id')->references('id')->on('equipment_loans');
            $table->foreign('equipment_item_id')->references('id')->on('equipment_master');
            $table->foreign('sent_by')->references('id')->on('users');
            $table->foreign('received_by_pic_id')->references('id')->on('users');
            $table->foreign('accepted_return_by')->references('id')->on('users');
        });

        DB::statement("ALTER TABLE order_equipment_items ADD COLUMN status equipment_item_status NOT NULL DEFAULT 'prepared'");
    }

    public function down(): void
    {
        Schema::dropIfExists('order_equipment_items');
        DB::statement("DROP TYPE IF EXISTS equipment_item_status");
    }
};
