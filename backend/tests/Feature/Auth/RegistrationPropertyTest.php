<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Eris\Generator;
use Eris\TestTrait;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * Feature: labventory-system, Property 1: Registration is well-formed.
 * Feature: labventory-system, Property 2: Registration uniqueness on NIM and email.
 * Feature: labventory-system, Property 3: Password length lower bound.
 * Feature: labventory-system, Property 4: Missing required fields enumerated.
 *
 * Validates: Requirements 1.1 — 1.7.
 */
class RegistrationPropertyTest extends TestCase
{
    use RefreshDatabase;
    use TestTrait;

    /**
     * Property 1 — every valid registration produces an active student
     * record with a hashed password and an issued Sanctum token that
     * authenticates a follow-up GET /api/auth/me.
     *
     * Eris doesn't re-run RefreshDatabase between iterations, so each
     * iteration runs inside its own DB savepoint that is rolled back
     * before the next sample, keeping iterations independent.
     */
    public function test_property_1_registration_is_well_formed(): void
    {
        $this->limitTo(15)->forAll(
            $this->validPasswordGen(),
        )->then(function (string $password): void {
            DB::beginTransaction();
            try {
                $payload = $this->validRegistrationPayload($password);

                $response = $this->postJson('/api/auth/register', $payload);

                $response->assertCreated();
                $response->assertJsonPath('success', true);
                $response->assertJsonPath('data.user.role', User::ROLE_STUDENT);
                $response->assertJsonPath('data.user.status', User::STATUS_ACTIVE);
                self::assertSame($payload['email'], $response->json('data.user.email'));

                $stored = User::query()->where('nim', $payload['nim'])->firstOrFail();
                self::assertTrue(Hash::check($password, $stored->password));
                self::assertNotSame($password, $stored->password);

                $token = $response->json('data.token');
                self::assertIsString($token);

                $me = $this->withHeaders(['Authorization' => "Bearer {$token}"])
                    ->getJson('/api/auth/me');
                $me->assertOk();
                self::assertSame((int) $stored->id, (int) $me->json('data.user.id'));
            } finally {
                DB::rollBack();
                $this->flushHeaders();
            }
        });
    }

    /**
     * Property 2 — duplicate NIM and duplicate email are both rejected
     * with field-scoped 422 errors.
     */
    public function test_property_2_registration_rejects_duplicate_nim_and_email(): void
    {
        $existing = User::factory()->student()->create();

        $this->limitTo(10)->forAll($this->validPasswordGen())
            ->then(function (string $password) use ($existing): void {
                $duplicateNim = $this->validRegistrationPayload($password);
                $duplicateNim['nim'] = $existing->nim;

                $this->postJson('/api/auth/register', $duplicateNim)
                    ->assertStatus(422)
                    ->assertJsonPath('success', false)
                    ->assertJsonValidationErrors(['nim']);

                $duplicateEmail = $this->validRegistrationPayload($password);
                $duplicateEmail['email'] = $existing->email;

                $this->postJson('/api/auth/register', $duplicateEmail)
                    ->assertStatus(422)
                    ->assertJsonValidationErrors(['email']);
            });
    }

    /**
     * Property 3 — passwords with length 0..7 are rejected; ≥ 8 are
     * accepted (assuming the rest of the payload is valid).
     */
    public function test_property_3_password_length_lower_bound(): void
    {
        $this->limitTo(15)->forAll(Generator\choose(0, 16))
            ->then(function (int $length): void {
                $password = $length === 0
                    ? ''
                    : str_repeat('A', $length).'1!';
                // The generator focuses on length; pad with safe chars so
                // failures only correlate with length, not other rules.
                $password = substr($password, 0, $length);

                $payload = $this->validRegistrationPayload($password);
                $payload['password_confirmation'] = $password;

                $response = $this->postJson('/api/auth/register', $payload);

                if ($length < 8) {
                    $response->assertStatus(422)
                        ->assertJsonValidationErrors(['password']);
                } else {
                    $response->assertCreated();
                }
            });
    }

    /**
     * Property 4 — for any non-empty subset of {name, nim, email, password}
     * removed from a valid payload, the 422 errors map contains exactly
     * the missing field keys.
     */
    public function test_property_4_missing_required_fields_enumerated(): void
    {
        $required = ['name', 'nim', 'email', 'password'];
        // 15 = 2^4 - 1 — every non-empty subset of {name, nim, email, password}
        $subsets = [];
        for ($mask = 1; $mask <= 15; $mask++) {
            $subset = [];
            foreach ($required as $i => $field) {
                if (($mask >> $i) & 1) {
                    $subset[] = $field;
                }
            }
            $subsets[] = $subset;
        }

        $this->forAll(Generator\elements(...$subsets))
            ->then(function (array $missing): void {
                $payload = $this->validRegistrationPayload();
                foreach ($missing as $field) {
                    unset($payload[$field]);
                }

                $response = $this->postJson('/api/auth/register', $payload);
                $response->assertStatus(422);

                $errors = $response->json('errors') ?? [];
                foreach ($missing as $field) {
                    self::assertArrayHasKey(
                        $field,
                        $errors,
                        'Expected missing field error for: '.$field,
                    );
                }
            });
    }

    /**
     * @return array{name: string, nim: string, email: string, password: string, password_confirmation: string}
     */
    private function validRegistrationPayload(?string $password = null): array
    {
        $password ??= 'Sup3rSecret!';
        $unique = bin2hex(random_bytes(4));

        return [
            'name' => 'Mahasiswa Test',
            'nim' => '21'.substr($unique, 0, 8),
            'email' => "user-{$unique}@example.test",
            'password' => $password,
            'password_confirmation' => $password,
        ];
    }

    private function validPasswordGen(): \Eris\Generator
    {
        return Generator\elements(
            'Password1!',
            'aBcDeFgH',
            'longerpassword',
            'IniRahasia123',
            '12345678',
        );
    }
}
