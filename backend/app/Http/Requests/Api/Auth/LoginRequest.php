<?php

namespace App\Http\Requests\Api\Auth;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validates POST /api/auth/login payloads (Requirement 2.1).
 *
 * Authentication itself is delegated to AuthService::login() so we can
 * surface "Invalid credentials" / "Account is disabled" with the correct
 * HTTP status (Requirements 2.2 — 2.4).
 */
class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'nim' => ['required', 'string'],
            'password' => ['required', 'string'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'nim' => 'NIM',
        ];
    }
}
