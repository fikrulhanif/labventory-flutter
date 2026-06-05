<?php

namespace App\Http\Requests\Api\Auth;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validates POST /api/auth/login payloads.
 *
 * Accepts a single `login` credential that may be either a student NIM or
 * an admin/laboran email (Requirement 19.1). For backward compatibility
 * with older clients that still send `nim`, the value is normalized into
 * `login` before validation (Requirement 19.6).
 *
 * Authentication itself is delegated to AuthService::login() so we can
 * surface "Invalid credentials" / "Account is disabled" with the correct
 * HTTP status (Requirements 19.3 — 19.5).
 */
class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Fold a legacy `nim` field into the canonical `login` field so both
     * the new unified clients and the original student client work.
     */
    protected function prepareForValidation(): void
    {
        if (! $this->filled('login') && $this->filled('nim')) {
            $this->merge(['login' => $this->input('nim')]);
        }
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'login' => ['required', 'string'],
            'password' => ['required', 'string'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'login' => 'NIM atau Email',
        ];
    }
}
