<?php

namespace Database\Factories;

use App\Models\Inventory;
use App\Models\Loan;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Loan>
 */
class LoanFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $borrow = fake()->dateTimeBetween('today', '+3 days');
        $return = (clone $borrow)->modify('+'.fake()->numberBetween(1, 7).' days');

        return [
            'user_id' => User::factory()->student(),
            'inventory_id' => Inventory::factory()->available(),
            'borrow_date' => $borrow->format('Y-m-d'),
            'return_date' => $return->format('Y-m-d'),
            'status' => Loan::STATUS_PENDING,
            'document' => 'ktm/'.fake()->sha1().'.jpg',
            'notes' => fake()->optional()->sentence(),
            'picked_up_at' => null,
            'returned_at' => null,
            'reject_reason' => null,
        ];
    }

    public function pending(): static
    {
        return $this->state(fn () => [
            'status' => Loan::STATUS_PENDING,
            'picked_up_at' => null,
            'returned_at' => null,
            'reject_reason' => null,
        ]);
    }

    public function approved(): static
    {
        return $this->state(fn () => [
            'status' => Loan::STATUS_APPROVED,
            'picked_up_at' => null,
            'returned_at' => null,
            'reject_reason' => null,
        ]);
    }

    public function rejected(string $reason = 'Insufficient justification'): static
    {
        return $this->state(fn () => [
            'status' => Loan::STATUS_REJECTED,
            'picked_up_at' => null,
            'returned_at' => null,
            'reject_reason' => $reason,
        ]);
    }

    public function borrowed(): static
    {
        return $this->state(fn () => [
            'status' => Loan::STATUS_BORROWED,
            'picked_up_at' => now(),
            'returned_at' => null,
            'reject_reason' => null,
        ]);
    }

    public function returned(): static
    {
        return $this->state(fn () => [
            'status' => Loan::STATUS_RETURNED,
            'picked_up_at' => now()->subDay(),
            'returned_at' => now(),
            'reject_reason' => null,
        ]);
    }
}
