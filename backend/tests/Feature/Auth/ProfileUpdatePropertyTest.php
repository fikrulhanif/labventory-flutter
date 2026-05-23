<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Eris\Generator;
use Eris\TestTrait;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Feature: labventory-system, Property 31: Profile update rules.
 *
 * For any profile update by an authenticated student:
 *   - email is updated only when unique across other users.
 *   - password is changed only when current_password matches.
 *   - nim, role, and status are never mutated through this endpoint.
 *   - successful responses return 200 with the new values.
 *
 * Validates: Requirements 12.1, 12.2, 12.3, 12.4, 12.5.
 */
class ProfileUpdatePropertyTest extends TestCase
{
    use RefreshDatabase;
    use TestTrait;

    public function test_property_31a_email_update_rejects_duplicates(): void
    {
        $other = User::factory()->student()->create();

        $this->limitTo(5)->forAll(Generator\elements('Wahyu', 'Andi', 'Putri', 'Ratna'))
            ->then(function (string $newName) use ($other): void {
                $user = User::factory()->student()->create();
                Sanctum::actingAs($user, ['mobile']);

                // Duplicate email -> 422
                $this->patchJson('/api/auth/profile', [
                    'name' => $newName,
                    'email' => $other->email,
                ])
                    ->assertStatus(422)
                    ->assertJsonValidationErrors(['email']);

                // Persisted email must be unchanged
                self::assertSame($user->email, $user->fresh()->email);
            });
    }

    public function test_property_31b_password_change_requires_current_password(): void
    {
        $this->limitTo(5)->forAll(Generator\elements('NewPass1!', 'AnotherSecret9'))
            ->then(function (string $newPassword): void {
                $user = User::factory()->student()->create([
                    'password' => Hash::make('correct-password'),
                ]);
                Sanctum::actingAs($user, ['mobile']);

                // Wrong current_password -> 422
                $this->patchJson('/api/auth/profile', [
                    'current_password' => 'definitely-wrong',
                    'password' => $newPassword,
                    'password_confirmation' => $newPassword,
                ])
                    ->assertStatus(422)
                    ->assertJsonValidationErrors(['current_password']);
                self::assertTrue(Hash::check('correct-password', $user->fresh()->password));

                // Correct current_password -> 200, hash updated
                $this->patchJson('/api/auth/profile', [
                    'current_password' => 'correct-password',
                    'password' => $newPassword,
                    'password_confirmation' => $newPassword,
                ])->assertOk();

                self::assertTrue(Hash::check($newPassword, $user->fresh()->password));
            });
    }

    public function test_property_31c_nim_role_and_status_are_never_mutable(): void
    {
        $this->limitTo(5)->forAll(Generator\elements('admin', 'laboran'))
            ->then(function (string $forbiddenRole): void {
                $user = User::factory()->student()->create();
                $original = $user->only(['nim', 'role', 'status']);

                Sanctum::actingAs($user, ['mobile']);

                $this->patchJson('/api/auth/profile', [
                    'name' => 'Renamed',
                    'nim' => '99999999',
                    'role' => $forbiddenRole,
                    'status' => 'inactive',
                ])->assertOk();

                $fresh = $user->fresh();
                self::assertSame($original['nim'], $fresh->nim);
                self::assertSame($original['role'], $fresh->role);
                self::assertSame($original['status'], $fresh->status);
                self::assertSame('Renamed', $fresh->name);
            });
    }
}
