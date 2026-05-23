<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Eris\Generator;
use Eris\TestTrait;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\TestCase;

/**
 * Feature: labventory-system, Property 9: Logout revokes only the presented token.
 * Feature: labventory-system, Property 10: Protected API endpoints reject unauthenticated requests.
 *
 * Validates: Requirements 3.2, 3.3, 3.4, 3.5, 17.5.
 */
class SessionPropertyTest extends TestCase
{
    use RefreshDatabase;
    use TestTrait;

    /**
     * Property 9 — logout revokes only the presented token; sibling
     * tokens issued for the same user remain valid.
     */
    public function test_property_9_logout_revokes_only_the_presented_token(): void
    {
        $user = User::factory()->student()->create();

        $plainA = $user->createToken('mobile-a', ['mobile'])->plainTextToken;
        $plainB = $user->createToken('mobile-b', ['mobile'])->plainTextToken;

        // Capture the token row IDs so we can verify which one is gone.
        [$idA] = explode('|', $plainA, 2);
        [$idB] = explode('|', $plainB, 2);

        // Logout with token A.
        $this->withHeaders(['Authorization' => "Bearer {$plainA}"])
            ->postJson('/api/auth/logout')
            ->assertOk();

        // Token A row is gone, token B row remains.
        self::assertNull(PersonalAccessToken::find((int) $idA));
        self::assertNotNull(PersonalAccessToken::find((int) $idB));
        self::assertSame(1, PersonalAccessToken::count());

        // Token B still authenticates the same user.
        $this->flushHeaders();
        $this->withHeaders(['Authorization' => "Bearer {$plainB}"])
            ->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('data.user.id', $user->id);
    }

    /**
     * Property 10 — every protected /api/* route returns 401 when called
     * without a Sanctum token. Public routes (register, login) are
     * excluded.
     */
    public function test_property_10_protected_routes_reject_unauthenticated_requests(): void
    {
        $protectedRoutes = [
            ['POST', '/api/auth/logout'],
            ['GET', '/api/auth/me'],
            ['PATCH', '/api/auth/profile'],
        ];

        $this->forAll(Generator\elements(...$protectedRoutes))
            ->then(function (array $route): void {
                [$method, $path] = $route;

                $this->json($method, $path, [])
                    ->assertStatus(401)
                    ->assertJsonPath('success', false)
                    ->assertJsonPath('message', 'Unauthenticated');
            });
    }
}
