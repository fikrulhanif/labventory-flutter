<?php

namespace App\Http\Middleware;

use App\Models\User;
use App\Support\ApiResponse;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Restrict access to the authenticated user's role.
 *
 * Used as `role:admin,laboran` on the admin dashboard route group
 * (Requirement 4.5) and as `role:student` on student-only API routes.
 */
class EnsureRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        /** @var User|null $user */
        $user = $request->user();

        if ($user === null || ! in_array($user->role, $roles, true)) {
            return $request->expectsJson()
                ? ApiResponse::forbidden('You are not authorized for this action.')
                : redirect()->route('login')
                    ->with('error', 'You are not authorized to access the dashboard');
        }

        if (! $user->isActive()) {
            return $request->expectsJson()
                ? ApiResponse::forbidden('Account is disabled')
                : redirect()->route('login')
                    ->with('error', 'Account is disabled');
        }

        return $next($request);
    }
}
