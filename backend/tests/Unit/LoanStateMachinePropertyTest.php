<?php

namespace Tests\Unit;

use App\Exceptions\InvalidLoanTransitionException;
use App\Models\Loan;
use App\Support\LoanStateMachine;
use Eris\Generator;
use Eris\TestTrait;
use PHPUnit\Framework\TestCase;

/**
 * Feature: labventory-system, Property 26: Loan state machine totality.
 *
 * For any loan in state `from` and any attempted transition action, the
 * system either accepts the transition (and the (from, to) pair is one of
 * the 4 allowed pairs) or rejects it; there is no input that produces
 * any other transition.
 *
 * Validates: Requirements 9.3, 9.4, 9.5, 10.3, 10.5, 10.7, 10.8.
 */
class LoanStateMachinePropertyTest extends TestCase
{
    use TestTrait;

    /**
     * The four (and only four) transitions that LoanStateMachine accepts.
     *
     * @var list<array{0: string, 1: string}>
     */
    private const ALLOWED_PAIRS = [
        [Loan::STATUS_PENDING, Loan::STATUS_APPROVED],
        [Loan::STATUS_PENDING, Loan::STATUS_REJECTED],
        [Loan::STATUS_APPROVED, Loan::STATUS_BORROWED],
        [Loan::STATUS_BORROWED, Loan::STATUS_RETURNED],
    ];

    private function statusGen(): \Eris\Generator
    {
        return Generator\elements(...Loan::ALL_STATUSES);
    }

    public function test_can_transition_returns_true_iff_pair_is_in_allowed_list(): void
    {
        $this->forAll($this->statusGen(), $this->statusGen())
            ->then(function (string $from, string $to): void {
                $isAllowed = self::pairIsAllowed($from, $to);

                self::assertSame(
                    $isAllowed,
                    LoanStateMachine::canTransition($from, $to),
                    "Disagreement on transition {$from} -> {$to}",
                );
            });
    }

    public function test_assert_transition_throws_iff_pair_is_not_in_allowed_list(): void
    {
        $this->forAll($this->statusGen(), $this->statusGen())
            ->then(function (string $from, string $to): void {
                $isAllowed = self::pairIsAllowed($from, $to);

                if ($isAllowed) {
                    LoanStateMachine::assertTransition($from, $to);
                    self::assertTrue(true, 'allowed transition did not throw');

                    return;
                }

                try {
                    LoanStateMachine::assertTransition($from, $to);
                    self::fail("expected InvalidLoanTransitionException for {$from} -> {$to}");
                } catch (InvalidLoanTransitionException $e) {
                    self::assertSame($from, $e->fromStatus);
                    self::assertSame($to, $e->toStatus);
                }
            });
    }

    public function test_no_transition_out_of_terminal_states(): void
    {
        $this->forAll($this->statusGen())
            ->then(function (string $to): void {
                self::assertFalse(LoanStateMachine::canTransition(Loan::STATUS_REJECTED, $to));
                self::assertFalse(LoanStateMachine::canTransition(Loan::STATUS_RETURNED, $to));
            });
    }

    public function test_terminal_statuses_match_design(): void
    {
        $terminal = LoanStateMachine::terminalStatuses();
        sort($terminal);

        self::assertSame(
            [Loan::STATUS_REJECTED, Loan::STATUS_RETURNED],
            $terminal,
        );
    }

    private static function pairIsAllowed(string $from, string $to): bool
    {
        foreach (self::ALLOWED_PAIRS as [$f, $t]) {
            if ($f === $from && $t === $to) {
                return true;
            }
        }

        return false;
    }
}
