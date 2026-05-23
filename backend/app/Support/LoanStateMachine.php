<?php

namespace App\Support;

use App\Exceptions\InvalidLoanTransitionException;
use App\Models\Loan;

/**
 * Single source of truth for the loan status state machine.
 *
 *   pending  -> approved | rejected
 *   approved -> borrowed
 *   borrowed -> returned
 *   rejected -> (terminal)
 *   returned -> (terminal)
 *
 * Validates Requirements 10.7, 10.8.
 *
 * Every loan status mutation in LoanService MUST go through assertTransition()
 * so no caller can introduce a forbidden transition by accident.
 */
final class LoanStateMachine
{
    /**
     * Mapping of "current status" -> list of allowed next statuses.
     *
     * @var array<string, list<string>>
     */
    public const ALLOWED = [
        Loan::STATUS_PENDING => [Loan::STATUS_APPROVED, Loan::STATUS_REJECTED],
        Loan::STATUS_APPROVED => [Loan::STATUS_BORROWED],
        Loan::STATUS_BORROWED => [Loan::STATUS_RETURNED],
        Loan::STATUS_REJECTED => [],
        Loan::STATUS_RETURNED => [],
    ];

    /**
     * Returns true when the (from -> to) transition is allowed.
     */
    public static function canTransition(string $from, string $to): bool
    {
        return in_array($to, self::ALLOWED[$from] ?? [], true);
    }

    /**
     * Throws when the transition is not allowed; otherwise no-op.
     *
     * @throws InvalidLoanTransitionException
     */
    public static function assertTransition(string $from, string $to): void
    {
        if (! self::canTransition($from, $to)) {
            throw new InvalidLoanTransitionException($from, $to);
        }
    }

    /**
     * Statuses from which no further transition is possible.
     *
     * @return list<string>
     */
    public static function terminalStatuses(): array
    {
        $terminal = [];

        foreach (self::ALLOWED as $status => $next) {
            if ($next === []) {
                $terminal[] = $status;
            }
        }

        return $terminal;
    }
}
