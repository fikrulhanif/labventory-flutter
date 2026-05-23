<?php

namespace App\Http\Middleware;

use App\Models\User;
use App\Support\ApiResponse;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Convenience middleware that authorizes only authenticated students with
 * an active status. Applied to the student-only mobile endpoints
 * (loans, profile update).
 */
class EnsureStudent
{
    public function handle(Request $request, Closure $next): Response
    {
        /** @var User|null $user */
        $user = $request->user();

        if ($user === null) {
            return ApiResponse::unauthenticated();
        }

        if (! $user->isStudent()) {
            return ApiResponse::forbidden('Forbidden');
        }

        if (! $user->isActive()) {
            return ApiResponse::forbidden('Account is disabled');
        }

        return $next($request);
    }
}
