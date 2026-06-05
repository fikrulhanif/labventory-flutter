<?php

namespace App\Http\Requests\Web\User;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

/**
 * Validates POST /admin/staff-users.
 *
 * - Role must be admin or laboran.
 * - No NIM — staff authenticate with email.
 * - Password required on create.
 * - The caller's password is verified separately before the form is
 *   shown (see StaffUserController::verifyCallerPassword).
 */
class StoreStaffUserRequest extends FormRequest
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
            'name'     => ['required', 'string', 'max:255'],
            'email'    => ['required', 'string', 'email:rfc', 'max:255', 'unique:users,email'],
            'role'     => ['required', 'in:admin,laboran'],
            'password' => ['required', 'string', Password::min(8), 'confirmed'],
            'status'   => ['nullable', 'in:active,inactive'],
        ];
    }
}
