<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    /**
     * Cached bcrypt hash of "password" so we don't pay the bcrypt cost
     * on every factory call.
     */
    protected static ?string $password;

    /**
     * Default state — student account, active, with a fake NIM.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'nim' => fake()->unique()->numerify('21##########'),
            'email' => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => static::$password ??= Hash::make('password'),
            'role' => User::ROLE_STUDENT,
            'status' => User::STATUS_ACTIVE,
            'remember_token' => Str::random(10),
        ];
    }

    /**
     * Student account (the default; here for readability at call sites).
     */
    public function student(): static
    {
        return $this->state(fn () => [
            'role' => User::ROLE_STUDENT,
        ]);
    }

    /**
     * Admin account — no NIM (admins authenticate with email).
     */
    public function admin(): static
    {
        return $this->state(fn () => [
            'role' => User::ROLE_ADMIN,
            'nim' => null,
        ]);
    }

    /**
     * Laboran account — no NIM.
     */
    public function laboran(): static
    {
        return $this->state(fn () => [
            'role' => User::ROLE_LABORAN,
            'nim' => null,
        ]);
    }

    /**
     * Disabled account — login should be rejected (Requirement 2.4).
     */
    public function inactive(): static
    {
        return $this->state(fn () => [
            'status' => User::STATUS_INACTIVE,
        ]);
    }

    /**
     * Mark the email as unverified.
     */
    public function unverified(): static
    {
        return $this->state(fn () => [
            'email_verified_at' => null,
        ]);
    }
}
