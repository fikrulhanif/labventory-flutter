<?php

namespace App\Http\Requests\Web\Loan;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validates POST /admin/loans/{loan}/reject (Requirement 9.4).
 *
 * The admin must supply a non-empty rejection reason which is persisted
 * on the loan record and the audit history.
 */
class RejectLoanRequest extends FormRequest
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
            'reject_reason' => ['required', 'string', 'min:3', 'max:1000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'reject_reason' => 'rejection reason',
        ];
    }
}
