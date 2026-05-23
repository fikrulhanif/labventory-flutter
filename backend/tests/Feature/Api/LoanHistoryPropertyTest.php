<?php

namespace Tests\Feature\Api;

use App\Models\Inventory;
use App\Models\Loan;
use App\Models\User;
use Eris\Generator;
use Eris\TestTrait;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Feature: labventory-system, Property 29: User loan history is scoped,
 * ordered, and paginated.
 *
 * Validates: Requirements 11.1, 11.2, 11.3, 11.5.
 */
class LoanHistoryPropertyTest extends TestCase
{
    use RefreshDatabase;
    use TestTrait;

    private User $student;

    protected function setUp(): void
    {
        parent::setUp();
        $this->student = User::factory()->student()->create();
        Sanctum::actingAs($this->student, ['mobile']);

        $other = User::factory()->student()->create();
        $inventory = Inventory::factory()->create();

        // Mixed status loans for self plus a few that belong to another
        // student so the scoping property has signal.
        Loan::factory()->pending()->count(3)->create([
            'user_id' => $this->student->id,
            'inventory_id' => $inventory->id,
        ]);
        Loan::factory()->approved()->count(2)->create([
            'user_id' => $this->student->id,
            'inventory_id' => $inventory->id,
        ]);
        Loan::factory()->returned()->count(2)->create([
            'user_id' => $this->student->id,
            'inventory_id' => $inventory->id,
        ]);
        Loan::factory()->pending()->count(4)->create([
            'user_id' => $other->id,
            'inventory_id' => $inventory->id,
        ]);
    }

    public function test_property_29a_scoped_to_authenticated_user(): void
    {
        $response = $this->getJson('/api/loans?per_page=50');
        $response->assertOk();

        foreach ($response->json('data.items') as $item) {
            self::assertSame($this->student->id, $item['user']['id']);
        }
    }

    public function test_property_29b_status_filter_returns_only_matching(): void
    {
        $this->forAll(Generator\elements(
            Loan::STATUS_PENDING,
            Loan::STATUS_APPROVED,
            Loan::STATUS_RETURNED,
        ))->then(function (string $status): void {
            $response = $this->getJson('/api/loans?status='.$status.'&per_page=50');
            $response->assertOk();

            foreach ($response->json('data.items') as $item) {
                self::assertSame($status, $item['status']);
            }
        });
    }

    public function test_property_29c_ordered_by_created_at_desc(): void
    {
        $response = $this->getJson('/api/loans?per_page=50');
        $response->assertOk();

        $timestamps = array_map(
            static fn (array $item): int => strtotime($item['created_at']),
            $response->json('data.items'),
        );

        $sorted = $timestamps;
        rsort($sorted);
        self::assertSame($sorted, $timestamps);
    }

    public function test_property_29d_default_page_size_is_15(): void
    {
        // Top up to make the default page size visible.
        $inventory = Inventory::factory()->create();
        Loan::factory()->pending()->count(15)->create([
            'user_id' => $this->student->id,
            'inventory_id' => $inventory->id,
        ]);

        $response = $this->getJson('/api/loans');
        $response->assertOk()
            ->assertJsonPath('data.meta.per_page', 15);
    }
}
