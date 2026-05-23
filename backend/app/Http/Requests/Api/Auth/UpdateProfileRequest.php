<?php

namespace App\Http\Requests\Api\Auth;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

/**
 * Validates PATCH /api/auth/profile payloads (Requirements 12.1 — 12.5).
 *
 * Notes:
 *   - nim, role, and status are intentionally NOT accepted here. They are
 *     dropped server-side via $this->safe()->only([...]) in the controller.
 *   - When `password` is present, `current_password` becomes mandatory and
 *     must match the stored hash; the actual hash check happens in
 *     AuthService::updateProfile() so the same envelope is produced
 *     regardless of where the validation fails.
 */
class UpdateProfileRequest extends FormRequest
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
        $userId = $this->user()?->getKey();

        return [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'email' => [
                'sometimes',
                'required',
                'string',
                'email:rfc',
                'max:255',
                Rule::unique('users', 'email')->ignore($userId),
            ],
            'current_password' => ['required_with:password', 'string'],
            'password' => ['sometimes', 'string', Password::min(8), 'confirmed'],
        ];
    }
}
