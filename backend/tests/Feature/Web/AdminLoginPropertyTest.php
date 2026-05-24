<?php

namespace Tests\Feature\Web;

use App\Models\User;
use Eris\Generator;
use Eris\TestTrait;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * Feature: labventory-system, Property 11: Admin login admits only admin
 * and laboran roles.
 *
 * For any user whose role is not in {admin, laboran}, submitting their
 * correct credentials to the admin login form is rejected with the
 * canonical message and no admin session is created.
 *
 * Validates: Requirement 4.2.
 */
class AdminLoginPropertyTest extends TestCase
{
    use RefreshDatabase;
    use TestTrait;

    public function test_property_11_only_staff_roles_can_log_in(): void
    {
        // Sample across the three role values so every iteration covers
        // exactly one case.
        $this->forAll(Generator\elements(User::ROLE_ADMIN, User::ROLE_LABORAN, User::ROLE_STUDENT))
            ->then(function (string $role): void {
                $password = 'correct-password';
                $factory = match ($role) {
                    User::ROLE_ADMIN => User::factory()->admin(),
                    User::ROLE_LABORAN => User::factory()->laboran(),
                    User::ROLE_STUDENT => User::factory()->student(),
                };

                $user = $factory->create(['password' => Hash::make($password)]);

                $response = $this->post('/login', [
                    'email' => $user->email,
                    'password' => $password,
                ]);

                if (in_array($role, [User::ROLE_ADMIN, User::ROLE_LABORAN], true)) {
                    $response->assertRedirect(route('admin.dashboard'));
                    $this->assertAuthenticatedAs($user);
                } else {
                    $response->assertRedirect();
                    $response->assertSessionHasErrors('email');
                    $errors = session('errors')->getBag('default')->get('email');
                    self::assertContains(
                        'You are not authorized to access the dashboard',
                        $errors,
                    );
                    $this->assertGuest();
                }

                // Reset state between iterations so the next sample starts
                // clean (RefreshDatabase only fires once per test method).
                \Illuminate\Support\Facades\Auth::guard('web')->logout();
                $this->flushSession();
            });
    }

    public function test_property_11_invalid_credentials_yield_canonical_error(): void
    {
        $admin = User::factory()->admin()->create([
            'password' => Hash::make('correct-password'),
        ]);

        $cases = Generator\elements('unknown_email', 'wrong_password');

        $this->forAll($cases)->then(function (string $case) use ($admin): void {
            $payload = match ($case) {
                'unknown_email' => [
                    'email' => 'nobody@example.test',
                    'password' => 'whatever',
                ],
                'wrong_password' => [
                    'email' => $admin->email,
                    'password' => 'definitely-wrong',
                ],
            };

            $response = $this->post('/login', $payload);
            $response->assertRedirect();
            $response->assertSessionHasErrors('email');
            $errors = session('errors')->getBag('default')->get('email');
            self::assertContains('Invalid email or password', $errors);
            $this->assertGuest();

            $this->flushSession();
        });
    }

    public function test_property_11_inactive_staff_cannot_log_in(): void
    {
        $password = 'correct-password';
        $admin = User::factory()->admin()->inactive()->create([
            'password' => Hash::make($password),
        ]);

        $response = $this->post('/login', [
            'email' => $admin->email,
            'password' => $password,
        ]);

        $response->assertRedirect();
        $response->assertSessionHasErrors('email');
        $errors = session('errors')->getBag('default')->get('email');
        self::assertContains('Account is disabled', $errors);
        $this->assertGuest();
    }
}
