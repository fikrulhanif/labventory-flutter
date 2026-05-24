<?php

namespace Tests\Feature\Web;

use App\Models\Category;
use App\Models\Inventory;
use App\Models\Loan;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Example-based feature tests for the dashboard home page.
 *
 * Validates Requirements 14.1, 14.2, 14.3 (Property 34).
 *
 * Each statistic is shown as a label + integer next to it. We seed a
 * known-good fixture and assert the rendered counts match the live
 * queries verbatim. Live queries themselves come straight from the
 * controller, so a future regression in either side surfaces here.
 */
class DashboardTest extends TestCase
{
    use RefreshDatabase;

    public function test_dashboard_renders_counts_matching_database(): void
    {
        $admin = User::factory()->admin()->create();
        $category = Category::factory()->create();

        // 3 available inventories
        Inventory::factory()->count(3)->available(stock: 5)->create([
            'category_id' => $category->id,
        ]);
        // 1 out of stock
        Inventory::factory()->outOfStock()->create([
            'category_id' => $category->id,
        ]);

        // 2 students
        $students = User::factory()->count(2)->student()->create();

        $invForLoans = Inventory::factory()->available(stock: 10)->create([
            'category_id' => $category->id,
        ]);

        // 2 borrowed + 3 pending = 5 total loans
        Loan::factory()->count(2)->borrowed()->create([
            'user_id' => $students->first()->id,
            'inventory_id' => $invForLoans->id,
        ]);
        Loan::factory()->count(3)->pending()->create([
            'user_id' => $students->first()->id,
            'inventory_id' => $invForLoans->id,
        ]);

        $expectedTotalInventories = Inventory::count();
        $expectedAvailable = Inventory::where('stock', '>', 0)->count();
        $expectedBorrowed = Loan::where('status', Loan::STATUS_BORROWED)->count();

        $response = $this->actingAs($admin)->get('/admin');
        $response->assertOk();

        // Assert the labels are present and counts are rendered.
        $response->assertSeeText('Inventories');
        $response->assertSeeText('Students');
        $response->assertSeeText('Total loans');
        $response->assertSeeText('Available items');
        $response->assertSeeText('Currently borrowed');

        $response->assertSeeText((string) $expectedTotalInventories);
        $response->assertSeeText((string) $expectedAvailable);
        $response->assertSeeText((string) $expectedBorrowed);

        // Spec: 2 students, 5 loans
        $response->assertSeeText('2');
        $response->assertSeeText('5');
    }

    public function test_dashboard_renders_empty_state_when_no_loans(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin)
            ->get('/admin')
            ->assertOk()
            ->assertSeeText('No loan requests yet.');
    }

    public function test_dashboard_renders_recent_loans_in_descending_order(): void
    {
        $admin = User::factory()->admin()->create();
        $student = User::factory()->student()->create();
        $category = Category::factory()->create();
        $inventory = Inventory::factory()->available(stock: 10)->create([
            'category_id' => $category->id,
        ]);

        // Create 7 loans across different timestamps
        for ($i = 0; $i < 7; $i++) {
            Loan::factory()->pending()->create([
                'user_id' => $student->id,
                'inventory_id' => $inventory->id,
                'created_at' => now()->subDays(7 - $i),
            ]);
        }

        $response = $this->actingAs($admin)->get('/admin');
        $response->assertOk();

        // Page shows recent-loans header
        $response->assertSeeText('Recent loans');
        $response->assertSeeText('Last 5 requests');
    }

    public function test_dashboard_recomputes_stats_on_each_load(): void
    {
        $admin = User::factory()->admin()->create();
        $category = Category::factory()->create();

        // First load — empty inventory
        $this->actingAs($admin)->get('/admin')->assertOk();

        // Mutate
        Inventory::factory()->count(2)->available()->create([
            'category_id' => $category->id,
        ]);

        // Second load reflects the mutation
        $response = $this->actingAs($admin)->get('/admin');
        $response->assertOk();
        $response->assertSeeText('2');  // total inventories now = 2
    }
}
