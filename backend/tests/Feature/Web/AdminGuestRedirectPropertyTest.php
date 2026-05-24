<?php

namespace Tests\Feature\Web;

use App\Models\User;
use Eris\Generator;
use Eris\TestTrait;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Feature: labventory-system, Property 12: Admin protected routes redirect
 * unauthenticated browsers to the login page.
 *
 * For any /admin/* route, an unauthenticated browser request is
 * redirected to /login. A logged-in student is redirected as well, with
 * the canonical "not authorized" flash message.
 *
 * Validates: Requirement 4.5.
 */
class AdminGuestRedirectPropertyTest extends TestCase
{
    use RefreshDatabase;
    use TestTrait;

    public function test_property_12_guest_browser_is_redirected_to_login(): void
    {
        // Future-proof: this list can grow as more /admin/* routes land
        // in tasks 9 — 12. For now, only the dashboard is wired.
        $this->forAll(Generator\elements('/admin', '/admin/'))
            ->then(function (string $path): void {
                $this->get($path)
                    ->assertRedirect('/login');
            });
    }

    public function test_property_12_student_session_cannot_access_admin(): void
    {
        $this->forAll(Generator\elements('/admin', '/admin/'))
            ->then(function (string $path): void {
                $student = User::factory()->student()->create();

                $this->actingAs($student)
                    ->get($path)
                    ->assertRedirect(route('login'));

                \Illuminate\Support\Facades\Auth::guard('web')->logout();
                $this->flushSession();
            });
    }

    public function test_property_12_staff_session_can_access_admin(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin)
            ->get('/admin')
            ->assertOk()
            ->assertSee('Dashboard');
    }
}
