<?php

namespace Database\Factories;

use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Models\Order;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class OrderFactory extends Factory
{
    protected $model = Order::class;

    public function definition(): array
    {
        return [
            'order_number' => 'SM-' . date('Ymd') . '-' . strtoupper(Str::random(4)),
            'status' => OrderStatus::PENDING->value,
            'pic_user_id' => User::factory(),
            'pic_name' => fake()->name(),
            'pic_phone' => '08' . fake()->numerify('##########'),
            'pic_relation' => fake()->randomElement(['anak', 'suami_istri', 'orang_tua', 'saudara']),
            'pic_address' => fake()->address(),
            'deceased_name' => fake()->name(),
            'deceased_dod' => now()->subDay(),
            'deceased_religion' => fake()->randomElement(['katolik', 'kristen', 'islam', 'hindu', 'buddha']),
            'pickup_address' => fake()->address(),
            'destination_address' => fake()->address(),
            'payment_status' => PaymentStatus::UNPAID->value,
        ];
    }

    public function confirmed(): static
    {
        return $this->state([
            'status' => OrderStatus::CONFIRMED->value,
            'scheduled_at' => now()->addDay(),
            'estimated_duration_hours' => 3,
        ]);
    }

    public function completed(): static
    {
        return $this->state([
            'status' => OrderStatus::COMPLETED->value,
            'completed_at' => now(),
        ]);
    }

    public function withConsumer(User $consumer = null): static
    {
        return $this->state([
            'pic_user_id' => $consumer?->id ?? User::factory()->consumer()->create()->id,
        ]);
    }

    public function withPackage(string $packageId): static
    {
        return $this->state(['package_id' => $packageId]);
    }
}
