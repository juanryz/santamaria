<?php

namespace Database\Factories;

use App\Models\StockItem;
use Illuminate\Database\Eloquent\Factories\Factory;

class StockItemFactory extends Factory
{
    protected $model = StockItem::class;

    public function definition(): array
    {
        return [
            'item_name' => fake()->unique()->word() . ' stock',
            'category' => fake()->randomElement(['peti', 'kain', 'bunga', 'perlengkapan_ibadah', 'perlengkapan_fisik']),
            'current_quantity' => fake()->numberBetween(5, 50),
            'minimum_quantity' => fake()->numberBetween(2, 10),
            'unit' => fake()->randomElement(['pcs', 'set', 'lembar']),
        ];
    }

    public function lowStock(): static
    {
        return $this->state([
            'current_quantity' => 1,
            'minimum_quantity' => 5,
        ]);
    }

    public function outOfStock(): static
    {
        return $this->state([
            'current_quantity' => 0,
            'minimum_quantity' => 5,
        ]);
    }
}
