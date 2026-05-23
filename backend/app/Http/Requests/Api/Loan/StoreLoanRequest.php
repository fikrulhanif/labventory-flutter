<?php

namespace App\Http\Requests\Api\Loan;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validates POST /api/loans payloads (Requirements 8.1 — 8.6).
 *
 * Stock check (Requirement 8.3) and duplicate-pending check (Requirement 8.8)
 * happen in LoanService::createLoan because they depend on a row-level
 * lock that a stateless validator cannot perform.
 */
class StoreLoanRequest extends FormRequest
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
            'inventory_id' => ['required', 'integer', 'exists:inventories,id'],
            'borrow_date' => ['required', 'date_format:Y-m-d', 'after_or_equal:today'],
            'return_date' => ['required', 'date_format:Y-m-d', 'after:borrow_date'],
            'document' => ['required', 'file', 'mimetypes:image/jpeg,image/png,application/pdf', 'max:2048'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'inventory_id.exists' => 'The selected inventory does not exist.',
            'borrow_date.after_or_equal' => 'The borrow date must be today or later.',
            'return_date.after' => 'The return date must be after the borrow date.',
            'document.mimetypes' => 'The document must be a JPEG, PNG, or PDF file.',
            'document.max' => 'The document may not be larger than 2 MB.',
        ];
    }
}
