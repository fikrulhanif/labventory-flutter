<?php

namespace App\Http\Requests\Web\User;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

/**
 * Validates PUT/PATCH /admin/users/{user} (Requirements 13.3, 13.4).
 *
 * Password is optional; supplying it requires confirmation. NIM and
 * email uniqueness ignore the current row.
 */
class UpdateUserRequest extends FormRequest
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
        $user = $this->route('user');
        $id = is_object($user) ? $user->id : $user;

        return [
            'name' => ['required', 'string', 'max:255'],
            'nim' => [
                'required',
                'string',
                'max:32',
                Rule::unique('users', 'nim')->ignore($id),
            ],
            'email' => [
                'required',
                'string',
                'email:rfc',
                'max:255',
                Rule::unique('users', 'email')->ignore($id),
            ],
            'password' => ['nullable', 'string', Password::min(8), 'confirmed'],
            'status' => ['required', 'in:active,inactive'],
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
