<?php

namespace App\Services;

use App\Models\FailedLogin;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;

/**
 * AuthService is the single owner of registration, login, logout, and
 * profile updates for the mobile app, plus the admin "set inactive" flow
 * that revokes Sanctum tokens.
 *
 * Validates Requirements 1.6, 1.7, 2.1 — 2.5, 3.4, 3.5, 12.1 — 12.5, 13.4.
 */
final class AuthService
{
    /**
     * Token ability granted to the mobile app on successful auth.
     */
    public const MOBILE_ABILITY = 'mobile';

    /**
     * Register a new student account and return a freshly minted token.
     *
     * @param  array{name: string, nim: string, email: string, password: string}  $data
     * @return array{user: User, token: string}
     */
    public function register(array $data): array
    {
        return DB::transaction(function () use ($data) {
            $user = User::create([
                'name' => $data['name'],
                'nim' => $data['nim'],
                'email' => $data['email'],
                'password' => Hash::make($data['password']),
                'role' => User::ROLE_STUDENT,
                'status' => User::STATUS_ACTIVE,
            ]);

            $token = $user->createToken('mobile', [self::MOBILE_ABILITY])->plainTextToken;

            return ['user' => $user->fresh(), 'token' => $token];
        });
    }

    /**
     * Authenticate a student with NIM + password.
     *
     * Throws ValidationException with the generic "Invalid credentials"
     * message for any unknown NIM or wrong password (Requirements 2.2,
     * 2.3) and a 403-style ValidationException for inactive accounts
     * (Requirement 2.4).
     *
     * @return array{user: User, token: string}
     *
     * @throws ValidationException
     */
    public function login(string $nim, string $password, ?string $ip = null): array
    {
        /** @var User|null $user */
        $user = User::query()->where('nim', $nim)->first();

        if ($user === null || ! Hash::check($password, $user->password)) {
            $this->logFailedLogin($nim, $ip);
            throw ValidationException::withMessages([
                'nim' => ['Invalid credentials'],
            ])->status(401);
        }

        if (! $user->isActive()) {
            $this->logFailedLogin($nim, $ip);
            throw ValidationException::withMessages([
                'nim' => ['Account is disabled'],
            ])->status(403);
        }

        $token = $user->createToken('mobile', [self::MOBILE_ABILITY])->plainTextToken;

        return ['user' => $user, 'token' => $token];
    }

    /**
     * Revoke the Sanctum token currently presented in the request.
     *
     * Only the supplied token is revoked; other tokens issued for the
     * same user remain valid (Requirement 3.5).
     */
    public function logout(?PersonalAccessToken $token): void
    {
        $token?->delete();
    }

    /**
     * Update a student's editable profile fields. Throws ValidationException
     * when the supplied current_password does not match the stored hash
     * (Requirement 12.3). The fields nim, role, and status are intentionally
     * not accepted here (Requirement 12.5).
     *
     * @param  array{name?: string, email?: string, current_password?: string, password?: string}  $data
     */
    public function updateProfile(User $user, array $data): User
    {
        return DB::transaction(function () use ($user, $data) {
            if (array_key_exists('name', $data)) {
                $user->name = $data['name'];
            }

            if (array_key_exists('email', $data)) {
                $user->email = $data['email'];
            }

            if (array_key_exists('password', $data) && $data['password'] !== null && $data['password'] !== '') {
                $current = $data['current_password'] ?? null;
                if ($current === null || ! Hash::check($current, $user->password)) {
                    throw ValidationException::withMessages([
                        'current_password' => ['The current password is incorrect.'],
                    ]);
                }
                $user->password = Hash::make($data['password']);
            }

            $user->save();

            return $user->fresh();
        });
    }

    /**
     * Disable a user's account and revoke every Sanctum token for that
     * user (Requirement 13.4). Used by the admin user manager.
     */
    public function setInactive(User $user): void
    {
        DB::transaction(function () use ($user): void {
            $user->status = User::STATUS_INACTIVE;
            $user->save();
            $user->tokens()->delete();
        });
    }

    /**
     * Append a row to the failed_logins audit table (Requirement 2.5).
     */
    private function logFailedLogin(string $nim, ?string $ip): void
    {
        FailedLogin::create([
            'nim' => $nim,
            'ip' => $ip,
            'created_at' => now(),
        ]);
    }
}
