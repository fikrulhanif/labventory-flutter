<?php

namespace Tests\Feature\Api;

use App\Models\Inventory;
use App\Models\User;
use Eris\Generator;
use Eris\TestTrait;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Feature: labventory-system, Property 23: Inventory detail returns 404
 * for unknown ids.
 *
 * For any integer id not present in the inventories table,
 * GET /api/inventories/{id} returns HTTP 404 with the canonical
 * envelope `{success: false, message: "Inventory not found"}`.
 *
 * Validates: Requirement 7.6.
 */
class InventoryDetailPropertyTest extends TestCase
{
    use RefreshDatabase;
    use TestTrait;

    protected function setUp(): void
    {
        parent::setUp();
        Sanctum::actingAs(User::factory()->student()->create(), ['mobile']);
    }

    public function test_property_23_returns_404_for_unknown_ids(): void
    {
        $existing = Inventory::factory()->count(3)->create();
        $existingIds = $existing->pluck('id')->all();

        $this->forAll(Generator\choose(1, 9_999))
            ->when(fn (int $id): bool => ! in_array($id, $existingIds, true))
            ->then(function (int $id): void {
                $this->getJson('/api/inventories/'.$id)
                    ->assertStatus(404)
                    ->assertJsonPath('success', false)
                    ->assertJsonPath('message', 'Inventory not found');
            });
    }

    public function test_property_23_returns_200_with_envelope_for_known_ids(): void
    {
        $existing = Inventory::factory()->count(3)->create();

        foreach ($existing as $inventory) {
            $this->getJson('/api/inventories/'.$inventory->id)
                ->assertOk()
                ->assertJsonPath('success', true)
                ->assertJsonPath('data.id', $inventory->id)
                ->assertJsonPath('data.code', $inventory->code);
        }
    }
}
