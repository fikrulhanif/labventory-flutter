<?php

namespace Tests\Unit;

use App\Models\Loan;
use App\Support\LoanStateMachine;
use Eris\Generator;
use Eris\TestTrait;
use PHPUnit\Framework\TestCase;

/**
 * Feature: labventory-system, Property 27: Stock conservation under
 * loan transitions.
 *
 * For any inventory and any sequence of loan transitions, the quantity
 *   Q = inventory.stock + |{ loans : status = "borrowed" }|
 * is invariant under the four allowed admin actions (approve, reject,
 * pickup, return). Equivalently:
 *   - approve / reject leave both terms unchanged.
 *   - pickup decrements stock by 1 and increments borrowed_count by 1.
 *   - return increments stock by 1 and decrements borrowed_count by 1.
 *
 * Validates: Requirements 9.3, 10.1, 10.2, 10.4, 10.6.
 *
 * This is a pure-state-machine test: we model the system as a value
 * `(stock, statuses[])` and reuse LoanStateMachine to decide what each
 * action does. No database calls. The same invariant is enforced by
 * LoanService::markPickedUp / markReturned in production through
 * row-level locks; the integration-side coverage lives in
 * tests/Feature/Web/LoanWorkflowTest.php.
 */
class StockConservationPropertyTest extends TestCase
{
    use TestTrait;

    /**
     * Generator producing one of the four admin actions.
     */
    private function actionGen(): \Eris\Generator
    {
        return Generator\elements('approve', 'reject', 'pickup', 'return');
    }

    /**
     * Generator producing a starting (stock, [statuses]) state.
     */
    private function stateGen(): \Eris\Generator
    {
        return Generator\tuple(
            Generator\choose(0, 10),
            Generator\vector(8, Generator\elements(...Loan::ALL_STATUSES)),
        );
    }

    /**
     * Apply action `$action` to loan at index `$idx`. Returns the new
     * `[stock, statuses]` pair. Invalid transitions are no-ops (matching
     * LoanService's exception-then-rollback behavior at production scale).
     *
     * @param  array{0: int, 1: list<string>}  $state
     * @return array{0: int, 1: list<string>}
     */
    private function step(array $state, string $action, int $idx): array
    {
        [$stock, $statuses] = $state;
        if (! isset($statuses[$idx])) {
            return $state;
        }

        $current = $statuses[$idx];
        $target = match ($action) {
            'approve' => Loan::STATUS_APPROVED,
            'reject' => Loan::STATUS_REJECTED,
            'pickup' => Loan::STATUS_BORROWED,
            'return' => Loan::STATUS_RETURNED,
        };

        if (! LoanStateMachine::canTransition($current, $target)) {
            return $state;
        }

        if ($action === 'pickup') {
            if ($stock <= 0) {
                return $state;  // simulates OutOfStockException + rollback
            }
            $stock -= 1;
        } elseif ($action === 'return') {
            $stock += 1;
        }

        $statuses[$idx] = $target;

        return [$stock, $statuses];
    }

    /**
     * Q(state) = stock + count(statuses where status = borrowed).
     *
     * @param  array{0: int, 1: list<string>}  $state
     */
    private function quantity(array $state): int
    {
        [$stock, $statuses] = $state;
        $borrowed = count(array_filter($statuses, static fn (string $s) => $s === Loan::STATUS_BORROWED));

        return $stock + $borrowed;
    }

    public function test_property_27_stock_plus_borrowed_count_is_invariant(): void
    {
        $sequenceGen = Generator\vector(20, Generator\tuple(
            $this->actionGen(),
            Generator\choose(0, 7),
        ));

        $this->forAll($this->stateGen(), $sequenceGen)
            ->then(function (array $initial, array $sequence): void {
                $expected = $this->quantity($initial);

                $state = $initial;
                foreach ($sequence as [$action, $idx]) {
                    $state = $this->step($state, $action, $idx);
                    self::assertSame(
                        $expected,
                        $this->quantity($state),
                        "Conservation broken after action {$action}@{$idx}",
                    );
                }
            });
    }

    public function test_property_27_pickup_decrements_stock_and_grows_borrowed(): void
    {
        $this->forAll(Generator\choose(1, 5))
            ->then(function (int $stock): void {
                $state = [$stock, [Loan::STATUS_APPROVED]];
                $next = $this->step($state, 'pickup', 0);

                self::assertSame($stock - 1, $next[0]);
                self::assertSame(Loan::STATUS_BORROWED, $next[1][0]);
            });
    }

    public function test_property_27_return_increments_stock_and_shrinks_borrowed(): void
    {
        $this->forAll(Generator\choose(0, 5))
            ->then(function (int $stock): void {
                $state = [$stock, [Loan::STATUS_BORROWED]];
                $next = $this->step($state, 'return', 0);

                self::assertSame($stock + 1, $next[0]);
                self::assertSame(Loan::STATUS_RETURNED, $next[1][0]);
            });
    }

    public function test_property_27_approve_and_reject_leave_stock_unchanged(): void
    {
        $this->forAll(
            Generator\choose(0, 10),
            Generator\elements('approve', 'reject'),
        )->then(function (int $stock, string $action): void {
            $state = [$stock, [Loan::STATUS_PENDING]];
            $next = $this->step($state, $action, 0);

            self::assertSame($stock, $next[0]);
        });
    }
}
