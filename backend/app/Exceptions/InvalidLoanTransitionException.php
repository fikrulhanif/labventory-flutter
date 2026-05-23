<?php

namespace App\Exceptions;

use RuntimeException;

/**
 * Thrown by LoanStateMachine when a loan status transition is not in the
 * allowed list. Maps to HTTP 422 on the API and a flash message on the
 * admin dashboard (Requirements 10.7, 10.8).
 */
class InvalidLoanTransitionException extends RuntimeException
{
    public function __construct(
        public readonly string $fromStatus,
        public readonly string $toStatus,
        string $message = 'Invalid status transition',
    ) {
        parent::__construct($message);
    }
}
