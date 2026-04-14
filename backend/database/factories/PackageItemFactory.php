<?php

namespace Database\Factories;

use App\Models\PackageItem;
use App\Models\Package;
use Illuminate\Database\Eloquent\Factories\Factory;

class PackageItemFactory extends Factory
{
    protected $model = PackageItem::class;

    public function definition(): array
    {
        return [
            'package_id' => Package::factory(),
            'item_name' => fake()->word() . ' item',
            'quantity' => fake()->numberBetween(1, 5),
            'unit' => fake()->randomElement(['pcs', 'set', 'lembar']),
            'category' => fake()->randomElement(['gudang', 'dekor', 'konsumsi', 'transportasi']),
            'stock_item_id' => null,
            'deduct_quantity' => null,
        ];
    }

    public function withStock(string $stockItemId, int $deductQty = 1): static
    {
        return $this->state([
            'stock_item_id' => $stockItemId,
            'deduct_quantity' => $deductQty,
        ]);
    }
}
