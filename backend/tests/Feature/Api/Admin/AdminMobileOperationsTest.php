<?php

namespace Tests\Feature\Api\Admin;

use App\Models\Category;
use App\Models\Inventory;
use App\Models\Loan;
use App\Models\LoanStatusHistory;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Example-based feature coverage for the admin mobile operations API
 * (Requirements 19-22 / Properties 45-48). Deterministic examples are
 * used instead of Eris to sidestep the RefreshDatabase savepoint conflicts
 * documented for the other property tests in this suite.
 *
 *   P45 - mobile login resolves by NIM or email
 *   P46 - admin inventory lookup by code is role-gated and exact
 *   P47 - active-loans-by-inventory returns exactly approved + borrowed
 *   P48 - mobile handover/return preserve the state machine + stock
 */
class AdminMobileOperationsTest extends TestCase
{
    use RefreshDatabase;

    private Category $category;

    protected function setUp(): void
    {
        parent::setUp();
        $this->category = Category::factory()->create();
    }

    private function inventory(int $stock = 5, string $code = 'INV-001'): Inventory
    {
        return Inventory::factory()->available(stock: $stock)->create([
            'category_id' => $this->category->id,
            'code' => $code,
        ]);
    }

    // -----------------------------------------------------------------
    // Property 45 — mobile login by NIM or email
    // -----------------------------------------------------------------

    public function test_student_can_log_in_with_nim(): void
    {
        $student = User::factory()->student()->create([
            'nim' => '231011401234',
            'password' => Hash::make('secret123'),
        ]);

        $this->postJson('/api/auth/login', [
            'login' => '231011401234',
            'password' => 'secret123',
        ])
            ->assertOk()
            ->assertJsonPath('data.user.id', $student->id)
            ->assertJsonPath('data.user.role', User::ROLE_STUDENT)
            ->assertJsonStructure(['data' => ['token']]);
    }

    public function test_admin_can_log_in_with_email_case_insensitive(): void
    {
        $admin = User::factory()->admin()->create([
            'email' => 'admin.case@labv.test',
            'password' => Hash::make('password'),
        ]);

        $this->postJson('/api/auth/login', [
            'login' => 'ADMIN.Case@labv.test',
            'password' => 'password',
        ])
            ->assertOk()
            ->assertJsonPath('data.user.id', $admin->id)
            ->assertJsonPath('data.user.role', User::ROLE_ADMIN);
    }

    public function test_legacy_nim_field_still_works(): void
    {
        $student = User::factory()->student()->create([
            'nim' => '231011409999',
            'password' => Hash::make('secret123'),
        ]);

        $this->postJson('/api/auth/login', [
            'nim' => '231011409999',
            'password' => 'secret123',
        ])
            ->assertOk()
            ->assertJsonPath('data.user.id', $student->id);
    }

    public function test_unknown_login_returns_401(): void
    {
        $this->postJson('/api/auth/login', [
            'login' => 'nobody@nowhere.test',
            'password' => 'whatever',
        ])
            ->assertStatus(401)
            ->assertJsonPath('message', 'Invalid credentials');
    }

    public function test_wrong_password_returns_401(): void
    {
        User::factory()->admin()->create([
            'email' => 'admin.wrongpw@labv.test',
            'password' => Hash::make('password'),
        ]);

        $this->postJson('/api/auth/login', [
            'login' => 'admin.wrongpw@labv.test',
            'password' => 'wrong',
        ])
            ->assertStatus(401)
            ->assertJsonPath('message', 'Invalid credentials');
    }

    public function test_inactive_account_returns_403(): void
    {
        User::factory()->admin()->inactive()->create([
            'email' => 'admin.disabled@labv.test',
            'password' => Hash::make('password'),
        ]);

        $this->postJson('/api/auth/login', [
            'login' => 'admin.disabled@labv.test',
            'password' => 'password',
        ])
            ->assertStatus(403)
            ->assertJsonPath('message', 'Account is disabled');
    }

    // -----------------------------------------------------------------
    // Property 46 — admin inventory lookup by code, role-gated and exact
    // -----------------------------------------------------------------

    public function test_admin_lookup_returns_inventory_by_code(): void
    {
        $admin = User::factory()->admin()->create();
        $inv = $this->inventory(code: 'INV-042');
        Sanctum::actingAs($admin, ['mobile']);

        $this->getJson('/api/admin/inventories/INV-042')
            ->assertOk()
            ->assertJsonPath('data.inventory.id', $inv->id)
            ->assertJsonPath('data.inventory.code', 'INV-042');
    }

    public function test_laboran_can_also_lookup(): void
    {
        $laboran = User::factory()->laboran()->create();
        $this->inventory(code: 'INV-077');
        Sanctum::actingAs($laboran, ['mobile']);

        $this->getJson('/api/admin/inventories/INV-077')
            ->assertOk()
            ->assertJsonPath('data.inventory.code', 'INV-077');
    }

    public function test_lookup_unknown_code_returns_404(): void
    {
        Sanctum::actingAs(User::factory()->admin()->create(), ['mobile']);

        $this->getJson('/api/admin/inventories/INV-NOPE')
            ->assertStatus(404)
            ->assertJsonPath('message', 'Inventory code not found');
    }

    public function test_student_is_forbidden_from_admin_lookup(): void
    {
        $this->inventory(code: 'INV-042');
        Sanctum::actingAs(User::factory()->student()->create(), ['mobile']);

        $this->getJson('/api/admin/inventories/INV-042')
            ->assertStatus(403);
    }

    public function test_unauthenticated_lookup_returns_401(): void
    {
        $this->inventory(code: 'INV-042');

        $this->getJson('/api/admin/inventories/INV-042')
            ->assertStatus(401);
    }

    // -----------------------------------------------------------------
    // Property 47 — active loans by inventory
    // -----------------------------------------------------------------

    public function test_active_loans_returns_only_approved_and_borrowed_ordered_asc(): void
    {
        $admin = User::factory()->admin()->create();
        $student = User::factory()->student()->create();
        $inv = $this->inventory(code: 'INV-100', stock: 10);

        $approved = Loan::factory()->approved()->create([
            'user_id' => $student->id,
            'inventory_id' => $inv->id,
            'created_at' => now()->subDays(2),
        ]);
        $borrowed = Loan::factory()->borrowed()->create([
            'user_id' => $student->id,
            'inventory_id' => $inv->id,
            'created_at' => now()->subDay(),
        ]);
        // Noise that must NOT appear:
        Loan::factory()->pending()->create([
            'user_id' => $student->id,
            'inventory_id' => $inv->id,
        ]);
        Loan::factory()->returned()->create([
            'user_id' => $student->id,
            'inventory_id' => $inv->id,
        ]);
        Loan::factory()->rejected()->create([
            'user_id' => $student->id,
            'inventory_id' => $inv->id,
        ]);

        Sanctum::actingAs($admin, ['mobile']);

        $response = $this->getJson('/api/admin/inventories/INV-100/loans')
            ->assertOk()
            ->assertJsonCount(2, 'data.loans');

        $ids = collect($response->json('data.loans'))->pluck('id')->all();
        self::assertSame([$approved->id, $borrowed->id], $ids, 'ordered created_at asc, only approved+borrowed');
    }

    public function test_active_loans_empty_when_none_active(): void
    {
        $admin = User::factory()->admin()->create();
        $student = User::factory()->student()->create();
        $inv = $this->inventory(code: 'INV-101');
        Loan::factory()->pending()->create([
            'user_id' => $student->id,
            'inventory_id' => $inv->id,
        ]);

        Sanctum::actingAs($admin, ['mobile']);

        $this->getJson('/api/admin/inventories/INV-101/loans')
            ->assertOk()
            ->assertJsonCount(0, 'data.loans');
    }

    public function test_active_loans_unknown_code_returns_404(): void
    {
        Sanctum::actingAs(User::factory()->admin()->create(), ['mobile']);

        $this->getJson('/api/admin/inventories/INV-NOPE/loans')
            ->assertStatus(404)
            ->assertJsonPath('message', 'Inventory code not found');
    }

    public function test_student_forbidden_from_active_loans(): void
    {
        $inv = $this->inventory(code: 'INV-102');
        Sanctum::actingAs(User::factory()->student()->create(), ['mobile']);

        $this->getJson('/api/admin/inventories/INV-102/loans')
            ->assertStatus(403);
    }

    // -----------------------------------------------------------------
    // Property 48 — handover / return preserve the state machine + stock
    // -----------------------------------------------------------------

    public function test_handover_transitions_approved_to_borrowed_and_decrements_stock(): void
    {
        $admin = User::factory()->admin()->create();
        $student = User::factory()->student()->create();
        $inv = $this->inventory(code: 'INV-200', stock: 5);
        $loan = Loan::factory()->approved()->create([
            'user_id' => $student->id,
            'inventory_id' => $inv->id,
        ]);

        Sanctum::actingAs($admin, ['mobile']);

        $this->postJson("/api/admin/loans/{$loan->id}/handover")
            ->assertOk()
            ->assertJsonPath('data.loan.status', Loan::STATUS_BORROWED);

        $fresh = $loan->fresh();
        self::assertSame(Loan::STATUS_BORROWED, $fresh->status);
        self::assertNotNull($fresh->picked_up_at);
        self::assertSame(4, $inv->fresh()->stock);

        // Audit row recorded with the acting admin (Req 22.9).
        $entry = LoanStatusHistory::query()->where('loan_id', $loan->id)->latest('id')->first();
        self::assertNotNull($entry);
        self::assertSame($admin->id, $entry->actor_user_id);
        self::assertSame(Loan::STATUS_BORROWED, $entry->to_status);
    }

    public function test_handover_rejected_when_not_approved(): void
    {
        $admin = User::factory()->admin()->create();
        $student = User::factory()->student()->create();
        $inv = $this->inventory(code: 'INV-201', stock: 5);
        $loan = Loan::factory()->pending()->create([
            'user_id' => $student->id,
            'inventory_id' => $inv->id,
        ]);

        Sanctum::actingAs($admin, ['mobile']);

        $this->postJson("/api/admin/loans/{$loan->id}/handover")
            ->assertStatus(422)
            ->assertJsonPath('message', 'Only approved loans can be marked as borrowed');

        self::assertSame(Loan::STATUS_PENDING, $loan->fresh()->status);
        self::assertSame(5, $inv->fresh()->stock);
    }

    public function test_handover_rejected_when_out_of_stock(): void
    {
        $admin = User::factory()->admin()->create();
        $student = User::factory()->student()->create();
        $inv = $this->inventory(code: 'INV-202', stock: 5);
        $inv->update(['stock' => 0, 'status' => Inventory::STATUS_OUT_OF_STOCK]);
        $loan = Loan::factory()->approved()->create([
            'user_id' => $student->id,
            'inventory_id' => $inv->id,
        ]);

        Sanctum::actingAs($admin, ['mobile']);

        $this->postJson("/api/admin/loans/{$loan->id}/handover")
            ->assertStatus(422)
            ->assertJsonPath('message', 'Inventory is out of stock');

        self::assertSame(Loan::STATUS_APPROVED, $loan->fresh()->status);
    }

    public function test_return_transitions_borrowed_to_returned_and_increments_stock(): void
    {
        $admin = User::factory()->admin()->create();
        $student = User::factory()->student()->create();
        $inv = $this->inventory(code: 'INV-203', stock: 3);
        $loan = Loan::factory()->borrowed()->create([
            'user_id' => $student->id,
            'inventory_id' => $inv->id,
            'picked_up_at' => now()->subDay(),
        ]);

        Sanctum::actingAs($admin, ['mobile']);

        $this->postJson("/api/admin/loans/{$loan->id}/return")
            ->assertOk()
            ->assertJsonPath('data.loan.status', Loan::STATUS_RETURNED);

        $fresh = $loan->fresh();
        self::assertSame(Loan::STATUS_RETURNED, $fresh->status);
        self::assertNotNull($fresh->returned_at);
        self::assertSame(4, $inv->fresh()->stock);
    }

    public function test_return_rejected_when_not_borrowed(): void
    {
        $admin = User::factory()->admin()->create();
        $student = User::factory()->student()->create();
        $inv = $this->inventory(code: 'INV-204', stock: 5);
        $loan = Loan::factory()->approved()->create([
            'user_id' => $student->id,
            'inventory_id' => $inv->id,
        ]);

        Sanctum::actingAs($admin, ['mobile']);

        $this->postJson("/api/admin/loans/{$loan->id}/return")
            ->assertStatus(422)
            ->assertJsonPath('message', 'Only borrowed loans can be marked as returned');

        self::assertSame(Loan::STATUS_APPROVED, $loan->fresh()->status);
    }

    public function test_student_forbidden_from_handover_and_return(): void
    {
        $student = User::factory()->student()->create();
        $inv = $this->inventory(code: 'INV-205', stock: 5);
        $loan = Loan::factory()->approved()->create([
            'user_id' => $student->id,
            'inventory_id' => $inv->id,
        ]);

        Sanctum::actingAs($student, ['mobile']);

        $this->postJson("/api/admin/loans/{$loan->id}/handover")->assertStatus(403);
        $this->postJson("/api/admin/loans/{$loan->id}/return")->assertStatus(403);
    }
}
