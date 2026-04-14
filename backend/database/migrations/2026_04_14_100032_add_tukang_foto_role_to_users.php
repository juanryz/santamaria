<?php

use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        // Role is stored as varchar in users table — no ALTER TYPE needed.
        // TUKANG_FOTO is simply a new string value used by the app.
        // The PHP Enum App\Enums\UserRole handles validation.
    }

    public function down(): void
    {
        //
    }
};
