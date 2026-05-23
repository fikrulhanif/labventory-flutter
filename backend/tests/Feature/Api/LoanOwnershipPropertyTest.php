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
 * Feature: labventory-system, Property 30: Loan ownership is enforced
 * on the detail endpoint.
 *
 * For any loan and authenticated student, GET /api/loans/{id} returns:
 *   - 200 if the loan's user_id matches the authenticated student;
 *   - 403 with message "Forbidden" otherwise.
 *
 * Validates: Requirement 11.4.
 */
class LoanOwnershipPropertyTest extends TestCase
{
    use RefreshDatabase;
    use TestTrait;

    public function test_property_30_detail_is_200_for_owner_403_for_others(): void
    {
        $this->forAll(Generator\choose(1, 5))
            ->then(function (int $idx): void {
                $owner = User::factory()->student()->create();
                $other = User::factory()->student()->create();
                $inventory = Inventory::factory()->create();

                $loan = Loan::factory()->pending()->create([
                    'user_id' => $owner->id,
                    'inventory_id' => $inventory->id,
                ]);

                // Owner sees their loan.
                Sanctum::actingAs($owner, ['mobile']);
                $this->getJson('/api/loans/'.$loan->id)
                    ->assertOk()
                    ->assertJsonPath('data.id', $loan->id);

                // Another student sees 403.
                $this->flushHeaders();
                Sanctum::actingAs($other, ['mobile']);
                $this->getJson('/api/loans/'.$loan->id)
                    ->assertStatus(403)
                    ->assertJsonPath('message', 'Forbidden');
            });
    }
}
