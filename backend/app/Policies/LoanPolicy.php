<?php

namespace App\Policies;

use App\Models\Loan;
use App\Models\User;

/**
 * Authorization rules for student-facing loan endpoints.
 *
 *   GET /api/loans/{id}            -> view: only the loan owner.
 *   GET /api/loans/{id}/document   -> downloadDocument: owner OR staff.
 *
 * Validates Requirements 11.4, 18.6.
 */
class LoanPolicy
{
    /**
     * The student who placed the loan can read it; nobody else.
     */
    public function view(User $user, Loan $loan): bool
    {
        return $user->id === $loan->user_id;
    }

    /**
     * The KTM document is private to the owner. Admin and laboran
     * accounts can download it for review purposes (Requirement 18.6).
     */
    public function downloadDocument(User $user, Loan $loan): bool
    {
        return $user->id === $loan->user_id || $user->isStaff();
    }
}
