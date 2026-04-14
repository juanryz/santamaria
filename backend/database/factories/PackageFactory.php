<?php

namespace Database\Factories;

use App\Models\Package;
use Illuminate\Database\Eloquent\Factories\Factory;

class PackageFactory extends Factory
{
    protected $model = Package::class;

    public function definition(): array
    {
        return [
            'name' => 'Paket ' . fake()->word(),
            'description' => fake()->sentence(),
            'base_price' => fake()->randomElement([5000000, 15000000, 50000000]),
            'is_active' => true,
        ];
    }
}
