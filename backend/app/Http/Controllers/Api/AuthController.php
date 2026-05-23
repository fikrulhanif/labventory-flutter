<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Auth\LoginRequest;
use App\Http\Requests\Api\Auth\RegisterRequest;
use App\Http\Requests\Api\Auth\UpdateProfileRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\AuthService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Mobile-app authentication endpoints.
 *
 *   POST   /api/auth/register   public
 *   POST   /api/auth/login      public
 *   POST   /api/auth/logout     auth:sanctum
 *   GET    /api/auth/me         auth:sanctum
 *   PATCH  /api/auth/profile    auth:sanctum + role:student
 *
 * All responses go through ApiResponse so the envelope (Requirement 17.1
 * — 17.4) stays consistent.
 */
class AuthController extends Controller
{
    public function __construct(private readonly AuthService $auth)
    {
    }

    public function register(RegisterRequest $request): JsonResponse
    {
        $payload = $this->auth->register($request->validated());

        return ApiResponse::created([
            'user' => new UserResource($payload['user']),
            'token' => $payload['token'],
        ], 'Registration successful');
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $payload = $this->auth->login(
            $request->string('nim')->toString(),
            $request->string('password')->toString(),
            $request->ip(),
        );

        return ApiResponse::ok([
            'user' => new UserResource($payload['user']),
            'token' => $payload['token'],
        ], 'Login successful');
    }

    public function logout(Request $request): JsonResponse
    {
        // Resolve the token from the raw bearer header so revocation works
        // regardless of any auth-state cache the test framework may keep
        // alive between requests in the same scenario.
        $bearer = $request->bearerToken();

        if ($bearer !== null) {
            $token = \Laravel\Sanctum\PersonalAccessToken::findToken($bearer);
            $this->auth->logout($token);
        } else {
            // Fallback for rare cases where the bearer is presented through
            // a non-header transport (cookies). The currently-resolved
            // token, if any, is revoked.
            $token = $request->user()?->currentAccessToken();
            if ($token instanceof \Laravel\Sanctum\PersonalAccessToken) {
                $this->auth->logout($token);
            }
        }

        return ApiResponse::message('Logged out');
    }

    public function me(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        return ApiResponse::ok(['user' => new UserResource($user)]);
    }

    public function updateProfile(UpdateProfileRequest $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        // Only allow editable fields to reach the service. nim, role, status
        // are dropped on the floor here (Requirement 12.5).
        $data = $request->safe()->only(['name', 'email', 'current_password', 'password']);

        $updated = $this->auth->updateProfile($user, $data);

        return ApiResponse::ok(
            ['user' => new UserResource($updated)],
            'Profile updated',
        );
    }
}
