<?php

namespace Database\Factories;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class UserFactory extends Factory
{
    protected $model = User::class;

    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'phone' => '08' . fake()->numerify('##########'),
            'email' => fake()->unique()->safeEmail(),
            'role' => UserRole::SERVICE_OFFICER->value,
            'password' => 'password123',
            'is_active' => true,
            'is_viewer' => false,
        ];
    }

    public function role(string|UserRole $role): static
    {
        $value = $role instanceof UserRole ? $role->value : $role;
        return $this->state(['role' => $value]);
    }

    public function consumer(): static
    {
        return $this->state([
            'role' => UserRole::CONSUMER->value,
            'pin' => '1234',
        ]);
    }

    public function driver(): static
    {
        return $this->state(['role' => UserRole::DRIVER->value]);
    }

    public function gudang(): static
    {
        return $this->state(['role' => UserRole::GUDANG->value]);
    }

    public function superAdmin(): static
    {
        return $this->state(['role' => UserRole::SUPER_ADMIN->value]);
    }

    public function viewer(): static
    {
        return $this->state([
            'role' => UserRole::VIEWER->value,
            'is_viewer' => true,
        ]);
    }

    public function supplier(): static
    {
        return $this->state([
            'role' => UserRole::SUPPLIER->value,
            'is_verified_supplier' => true,
        ]);
    }
}
