<?php

namespace Tests\Feature\Api;

use App\Models\Category;
use App\Models\Inventory;
use App\Models\User;
use Eris\Generator;
use Eris\TestTrait;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Feature: labventory-system, Property 22: Inventory list filters,
 * ordering, and pagination.
 *
 * For any inventory list request:
 *   - every returned item satisfies category_id, status, and search
 *     filters when present;
 *   - per_page is clamped to [1, 50] with default 15.
 *
 * Validates: Requirements 7.1, 7.2, 7.3, 7.4, 7.7.
 */
class InventoryListPropertyTest extends TestCase
{
    use RefreshDatabase;
    use TestTrait;

    protected function setUp(): void
    {
        parent::setUp();
        Sanctum::actingAs(User::factory()->student()->create(), ['mobile']);
    }

    public function test_property_22a_category_filter_returns_only_matching_items(): void
    {
        $catA = Category::factory()->create();
        $catB = Category::factory()->create();
        Inventory::factory()->count(4)->create(['category_id' => $catA->id]);
        Inventory::factory()->count(3)->create(['category_id' => $catB->id]);

        $this->forAll(Generator\elements($catA->id, $catB->id))
            ->then(function (int $categoryId): void {
                $response = $this->getJson('/api/inventories?category_id='.$categoryId);
                $response->assertOk();

                $items = $response->json('data.items');
                self::assertNotEmpty($items);

                foreach ($items as $item) {
                    self::assertSame(
                        $categoryId,
                        $item['category']['id'] ?? null,
                        'Found item with mismatched category_id',
                    );
                }
            });
    }

    public function test_property_22b_status_filter_returns_only_matching_items(): void
    {
        Inventory::factory()->available()->count(5)->create();
        Inventory::factory()->outOfStock()->count(3)->create();

        $this->forAll(Generator\elements(
            Inventory::STATUS_AVAILABLE,
            Inventory::STATUS_OUT_OF_STOCK,
        ))->then(function (string $status): void {
            $response = $this->getJson('/api/inventories?status='.$status);
            $response->assertOk();

            foreach ($response->json('data.items') as $item) {
                self::assertSame($status, $item['status']);
            }
        });
    }

    public function test_property_22c_search_filter_is_case_insensitive_substring(): void
    {
        // Idempotent seed: re-running this test method or its eris
        // iterations must not double-insert.
        Inventory::firstOrCreate(['code' => 'INV-001'], Inventory::factory()->raw([
            'name' => 'Arduino Uno R3', 'code' => 'INV-001',
        ]));
        Inventory::firstOrCreate(['code' => 'INV-002'], Inventory::factory()->raw([
            'name' => 'ESP32 DevKit', 'code' => 'INV-002',
        ]));
        Inventory::firstOrCreate(['code' => 'INV-010'], Inventory::factory()->raw([
            'name' => 'Logitech Webcam', 'code' => 'INV-010',
        ]));

        $cases = [
            ['arduino', ['INV-001']],
            ['ARDUINO', ['INV-001']],
            ['esp', ['INV-002']],
            ['inv-01', ['INV-010']],
        ];

        $this->forAll(Generator\elements(...$cases))
            ->then(function (array $case): void {
                [$query, $expectedCodes] = $case;

                $response = $this->getJson('/api/inventories?search='.urlencode($query));
                $response->assertOk();

                $items = $response->json('data.items');
                $codes = array_map(static fn ($it) => $it['code'], $items);
                sort($codes);

                self::assertSame($expectedCodes, $codes);

                foreach ($items as $item) {
                    $haystack = strtolower($item['name'].' '.$item['code']);
                    self::assertStringContainsString(strtolower($query), $haystack);
                }
            });
    }

    public function test_property_22d_per_page_is_clamped_between_1_and_50(): void
    {
        Inventory::factory()->count(60)->create();

        $cases = Generator\choose(-5, 200);

        $this->limitTo(15)->forAll($cases)
            ->then(function (int $rawPerPage): void {
                $response = $this->getJson('/api/inventories?per_page='.$rawPerPage);
                $response->assertOk();

                $perPage = (int) $response->json('data.meta.per_page');
                self::assertGreaterThanOrEqual(1, $perPage);
                self::assertLessThanOrEqual(50, $perPage);

                if ($rawPerPage >= 1 && $rawPerPage <= 50) {
                    self::assertSame($rawPerPage, $perPage);
                }
            });
    }

    public function test_property_22e_default_page_size_is_15(): void
    {
        Inventory::factory()->count(20)->create();

        $response = $this->getJson('/api/inventories');
        $response->assertOk();

        self::assertSame(15, (int) $response->json('data.meta.per_page'));
        self::assertCount(15, $response->json('data.items'));
    }
}
