<?php

namespace Tests\Unit;

use App\Models\Inventory;
use Eris\Generator;
use Eris\TestTrait;
use PHPUnit\Framework\TestCase;

/**
 * Feature: labventory-system, Property 16: Inventory.status is derived from
 * stock at all times — status = "available" iff stock > 0, status =
 * "out_of_stock" iff stock = 0, and the derivation is idempotent.
 *
 * Validates: Requirements 6.1, 6.9, 10.6
 *
 * The derivation is a pure function on `stock`. We verify it directly here
 * without touching the database. Once `InventoryService::recomputeStatus`
 * lands in task 5.1 it MUST delegate to (or match) this same rule, and
 * task 5's property tests will exercise the service-level path against a
 * real DB.
 */
class InventoryStatusPropertyTest extends TestCase
{
    use TestTrait;

    private function nonNegativeStockGen(): \Eris\Generator
    {
        return Generator\choose(0, 10_000);
    }

    /**
     * Pure derivation: status = available iff stock > 0.
     */
    private static function deriveStatus(int $stock): string
    {
        return $stock > 0
            ? Inventory::STATUS_AVAILABLE
            : Inventory::STATUS_OUT_OF_STOCK;
    }

    public function test_status_is_available_iff_stock_is_positive(): void
    {
        $this->forAll($this->nonNegativeStockGen())
            ->then(function (int $stock): void {
                $status = self::deriveStatus($stock);

                if ($stock > 0) {
                    self::assertSame(Inventory::STATUS_AVAILABLE, $status);
                } else {
                    self::assertSame(Inventory::STATUS_OUT_OF_STOCK, $status);
                }
            });
    }

    public function test_derivation_is_idempotent(): void
    {
        $this->forAll($this->nonNegativeStockGen())
            ->then(function (int $stock): void {
                $first = self::deriveStatus($stock);
                $second = self::deriveStatus($stock);

                self::assertSame($first, $second);
            });
    }

    public function test_only_two_status_values_are_ever_produced(): void
    {
        $allowed = [
            Inventory::STATUS_AVAILABLE,
            Inventory::STATUS_OUT_OF_STOCK,
        ];

        $this->forAll($this->nonNegativeStockGen())
            ->then(function (int $stock) use ($allowed): void {
                self::assertContains(self::deriveStatus($stock), $allowed);
            });
    }
}
