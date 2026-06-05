<?php

namespace App\Http\Requests\Web\User;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

/**
 * Validates PUT /admin/staff-users/{user}.
 *
 * Password is optional on update; supplying it requires confirmation.
 * Email uniqueness ignores the current row.
 * Role stays editable (admin ↔ laboran).
 */
class UpdateStaffUserRequest extends FormRequest
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
        $user = $this->route('staff_user');
        $id   = is_object($user) ? $user->id : $user;

        return [
            'name'     => ['required', 'string', 'max:255'],
            'email'    => [
                'required', 'string', 'email:rfc', 'max:255',
                Rule::unique('users', 'email')->ignore($id),
            ],
            'role'     => ['required', 'in:admin,laboran'],
            'password' => ['nullable', 'string', Password::min(8), 'confirmed'],
            'status'   => ['required', 'in:active,inactive'],
        ];
    }
}
