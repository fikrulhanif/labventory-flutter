<?php

namespace Tests\Feature\Auth;

use App\Models\FailedLogin;
use App\Models\User;
use Eris\Generator;
use Eris\TestTrait;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * Feature: labventory-system, Property 5: Login issues a working token.
 * Feature: labventory-system, Property 6: Wrong credentials return 401 "Invalid credentials".
 * Feature: labventory-system, Property 7: Inactive accounts cannot log in.
 * Feature: labventory-system, Property 8: Failed login attempts are recorded.
 *
 * Validates: Requirements 2.1 — 2.5.
 */
class LoginPropertyTest extends TestCase
{
    use RefreshDatabase;
    use TestTrait;

    /**
     * Property 5 — for any active student with a known plaintext password,
     * the issued token authenticates a follow-up GET /api/auth/me as the
     * same user. Each iteration runs in its own DB transaction so users
     * created earlier don't leak forward.
     */
    public function test_property_5_login_issues_working_token(): void
    {
        $this->limitTo(8)->forAll($this->plainPasswordGen())
            ->then(function (string $password): void {
                DB::beginTransaction();
                try {
                    $user = User::factory()->student()->create([
                        'password' => bcrypt($password),
                    ]);

                    $response = $this->postJson('/api/auth/login', [
                        'nim' => $user->nim,
                        'password' => $password,
                    ]);

                    $response->assertOk()
                        ->assertJsonPath('success', true)
                        ->assertJsonPath('data.user.id', $user->id);

                    $token = $response->json('data.token');
                    self::assertIsString($token);

                    $me = $this->withHeaders(['Authorization' => "Bearer {$token}"])
                        ->getJson('/api/auth/me');
                    $me->assertOk();
                    self::assertSame((int) $user->id, (int) $me->json('data.user.id'));
                } finally {
                    DB::rollBack();
                    $this->flushHeaders();
                }
            });
    }

    /**
     * Property 6 — both unknown NIM and wrong password produce HTTP 401
     * "Invalid credentials". Status and message are indistinguishable
     * between the two so attackers can't enumerate NIMs.
     */
    public function test_property_6_wrong_credentials_yield_401_invalid_credentials(): void
    {
        $known = User::factory()->student()->create([
            'password' => bcrypt('correct-password'),
        ]);

        $cases = Generator\elements('unknown_nim', 'wrong_password');

        $this->limitTo(15)->forAll($cases)
            ->then(function (string $case) use ($known): void {
                $payload = match ($case) {
                    'unknown_nim' => [
                        'nim' => '21'.bin2hex(random_bytes(4)),
                        'password' => 'whatever',
                    ],
                    'wrong_password' => [
                        'nim' => $known->nim,
                        'password' => 'definitely-not-it',
                    ],
                };

                $this->postJson('/api/auth/login', $payload)
                    ->assertStatus(401)
                    ->assertJsonPath('success', false)
                    ->assertJsonPath('message', 'Invalid credentials');
            });
    }

    /**
     * Property 7 — inactive accounts are rejected with HTTP 403
     * "Account is disabled" even when the password is correct.
     */
    public function test_property_7_inactive_accounts_cannot_log_in(): void
    {
        $this->limitTo(5)->forAll($this->plainPasswordGen())
            ->then(function (string $password): void {
                $user = User::factory()->student()->inactive()->create([
                    'password' => bcrypt($password),
                ]);

                $this->postJson('/api/auth/login', [
                    'nim' => $user->nim,
                    'password' => $password,
                ])
                    ->assertStatus(403)
                    ->assertJsonPath('message', 'Account is disabled');
            });
    }

    /**
     * Property 8 — every failed login attempt (unknown NIM, wrong
     * password, or inactive account) appends one row to failed_logins.
     */
    public function test_property_8_failed_logins_are_recorded(): void
    {
        $known = User::factory()->student()->create([
            'password' => bcrypt('correct-password'),
        ]);
        $inactive = User::factory()->student()->inactive()->create([
            'password' => bcrypt('correct-password'),
        ]);

        $cases = Generator\elements('unknown_nim', 'wrong_password', 'inactive');

        $this->limitTo(15)->forAll($cases)
            ->then(function (string $case) use ($known, $inactive): void {
                $before = FailedLogin::count();
                $startedAt = now();

                $payload = match ($case) {
                    'unknown_nim' => [
                        'nim' => '21'.bin2hex(random_bytes(4)),
                        'password' => 'whatever',
                    ],
                    'wrong_password' => [
                        'nim' => $known->nim,
                        'password' => 'wrong',
                    ],
                    'inactive' => [
                        'nim' => $inactive->nim,
                        'password' => 'correct-password',
                    ],
                };

                $this->postJson('/api/auth/login', $payload);

                self::assertSame($before + 1, FailedLogin::count());

                $latest = FailedLogin::latest('id')->first();
                self::assertNotNull($latest);
                self::assertSame($payload['nim'], $latest->nim);
                self::assertGreaterThanOrEqual(
                    $startedAt->timestamp,
                    $latest->created_at->timestamp,
                );
            });
    }

    private function plainPasswordGen(): \Eris\Generator
    {
        return Generator\elements(
            'Password1!',
            'aBcDeFgH',
            'longerpassword',
            'CorrectHorseBatteryStaple',
            '12345678',
        );
    }
}
