<?php

namespace App\Console\Commands;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;

class CreateSuperAdmin extends Command
{
    protected $signature = 'superadmin:create
                            {--name= : Nama lengkap super admin}
                            {--email= : Alamat email}
                            {--phone= : Nomor HP}
                            {--password= : Password (min 8 karakter)}';

    protected $description = 'Buat akun Super Admin pertama untuk sistem Santa Maria';

    public function handle(): int
    {
        $this->info('=== Buat Akun Super Admin ===');

        $name     = $this->option('name')     ?? $this->ask('Nama lengkap');
        $email    = $this->option('email')    ?? $this->ask('Email');
        $phone    = $this->option('phone')    ?? $this->ask('Nomor HP');
        $password = $this->option('password') ?? $this->secret('Password (min 8 karakter)');

        if (strlen($password) < 8) {
            $this->error('Password minimal 8 karakter.');
            return self::FAILURE;
        }

        if (User::where('email', $email)->exists()) {
            $this->error("Email {$email} sudah terdaftar.");
            return self::FAILURE;
        }

        if (User::where('phone', $phone)->exists()) {
            $this->error("Nomor HP {$phone} sudah terdaftar.");
            return self::FAILURE;
        }

        $user = User::create([
            'name'      => $name,
            'email'     => $email,
            'phone'     => $phone,
            'role'      => UserRole::SUPER_ADMIN->value,
            'password'  => Hash::make($password),
            'is_active' => true,
            'is_viewer' => false,
        ]);

        $this->info("✓ Super Admin berhasil dibuat:");
        $this->table(['Field', 'Nilai'], [
            ['ID',    $user->id],
            ['Nama',  $user->name],
            ['Email', $user->email],
            ['Phone', $user->phone],
            ['Role',  $user->role],
        ]);

        return self::SUCCESS;
    }
}
