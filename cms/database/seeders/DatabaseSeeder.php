<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'admin@flyupengine.com'],
            [
                'name' => 'Administrator',
                'password' => Hash::make('Sempaksempak12'),
            ]
        );
    }
}
