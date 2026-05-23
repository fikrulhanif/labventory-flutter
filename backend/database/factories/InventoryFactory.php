<?php

namespace Database\Factories;

use App\Models\Category;
use App\Models\Inventory;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Inventory>
 */
class InventoryFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $stock = fake()->numberBetween(0, 10);

        return [
            'category_id' => Category::factory(),
            'name' => fake()->words(3, asText: true),
            'code' => 'INV-'.fake()->unique()->numerify('####'),
            'stock' => $stock,
            'description' => fake()->optional()->sentence(),
            'image' => null,
            'qr_code' => null,
            'status' => $stock > 0
                ? Inventory::STATUS_AVAILABLE
                : Inventory::STATUS_OUT_OF_STOCK,
        ];
    }

    public function available(int $stock = 5): static
    {
        return $this->state(fn () => [
            'stock' => max(1, $stock),
            'status' => Inventory::STATUS_AVAILABLE,
        ]);
    }

    public function outOfStock(): static
    {
        return $this->state(fn () => [
            'stock' => 0,
            'status' => Inventory::STATUS_OUT_OF_STOCK,
        ]);
    }
}
