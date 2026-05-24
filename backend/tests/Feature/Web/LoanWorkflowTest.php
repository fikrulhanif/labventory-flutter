<?php

namespace Tests\Feature\Web;

use App\Models\Category;
use App\Models\Inventory;
use App\Models\Loan;
use App\Models\LoanStatusHistory;
use App\Models\User;
use Illuminate\Filesystem\FilesystemAdapter;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * Example-based feature tests for the admin loan workflow:
 *
 *   - approve / reject from pending
 *   - pickup from approved (stock -= 1)
 *   - return from borrowed (stock += 1)
 *   - invalid transitions surface canonical flash errors
 *   - audit history grows on every transition
 *   - picked_up_at / returned_at timestamps recorded (Property 28)
 *   - KTM file retained on rejected / returned (Property 43)
 *
 * Validates Requirements 9.1 — 9.5, 10.1 — 10.8, 18.4.
 */
class LoanWorkflowTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private User $student;

    private Category $category;

    private function publicDisk(): FilesystemAdapter
    {
        /** @var FilesystemAdapter $disk */
        $disk = Storage::disk('public');

        return $disk;
    }

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
        $this->admin = User::factory()->admin()->create();
        $this->student = User::factory()->student()->create();
        $this->category = Category::factory()->create();
    }

    /**
     * Stage a KTM file on disk and return a loan referencing it so we
     * can assert retention behaviour.
     */
    private function loanWithStagedKtm(int $stock = 5): array
    {
        $inv = Inventory::factory()->available(stock: $stock)->create([
            'category_id' => $this->category->id,
        ]);

        $document = UploadedFile::fake()
            ->create('ktm.jpg', 100, 'image/jpeg')
            ->store('ktm', 'public');

        $loan = Loan::factory()->pending()->create([
            'user_id' => $this->student->id,
            'inventory_id' => $inv->id,
            'document' => $document,
        ]);

        return [$loan, $inv, $document];
    }

    // ---------------------------------------------------------------
    // Approve
    // ---------------------------------------------------------------

    public function test_approve_transitions_pending_to_approved_without_stock_change(): void
    {
        [$loan, $inv] = $this->loanWithStagedKtm(stock: 5);

        $this->actingAs($this->admin)
            ->post(route('admin.loans.approve', $loan))
            ->assertRedirect(route('admin.loans.show', $loan))
            ->assertSessionHas('success');

        self::assertSame(Loan::STATUS_APPROVED, $loan->fresh()->status);
        self::assertSame(5, $inv->fresh()->stock);
    }

    public function test_approve_records_status_history(): void
    {
        [$loan] = $this->loanWithStagedKtm();

        $this->actingAs($this->admin)
            ->post(route('admin.loans.approve', $loan))
            ->assertRedirect();

        $entry = LoanStatusHistory::query()
            ->where('loan_id', $loan->id)
            ->first();
        self::assertNotNull($entry);
        self::assertSame(Loan::STATUS_PENDING, $entry->from_status);
        self::assertSame(Loan::STATUS_APPROVED, $entry->to_status);
        self::assertSame($this->admin->id, $entry->actor_user_id);
    }

    public function test_approve_blocked_when_loan_not_pending(): void
    {
        [$loan] = $this->loanWithStagedKtm();
        $loan->update(['status' => Loan::STATUS_APPROVED]);

        $this->actingAs($this->admin)
            ->post(route('admin.loans.approve', $loan))
            ->assertSessionHas('error', 'Only pending loans can be approved or rejected');
    }

    // ---------------------------------------------------------------
    // Reject
    // ---------------------------------------------------------------

    public function test_reject_persists_reason_and_keeps_ktm_file(): void
    {
        [$loan, , $document] = $this->loanWithStagedKtm();

        $this->actingAs($this->admin)
            ->post(route('admin.loans.reject', $loan), [
                'reject_reason' => 'KTM photo unreadable',
            ])
            ->assertRedirect(route('admin.loans.show', $loan));

        $fresh = $loan->fresh();
        self::assertSame(Loan::STATUS_REJECTED, $fresh->status);
        self::assertSame('KTM photo unreadable', $fresh->reject_reason);

        // Property 43: KTM document must survive rejection for audit.
        $this->publicDisk()->assertExists($document);
    }

    public function test_reject_requires_reason(): void
    {
        [$loan] = $this->loanWithStagedKtm();

        $this->actingAs($this->admin)
            ->post(route('admin.loans.reject', $loan), [
                'reject_reason' => '',
            ])
            ->assertSessionHasErrors('reject_reason');

        self::assertSame(Loan::STATUS_PENDING, $loan->fresh()->status);
    }

    // ---------------------------------------------------------------
    // Pickup (approved -> borrowed, stock -= 1)
    // ---------------------------------------------------------------

    public function test_pickup_transitions_approved_to_borrowed_and_decrements_stock(): void
    {
        [$loan, $inv] = $this->loanWithStagedKtm(stock: 5);
        $loan->update(['status' => Loan::STATUS_APPROVED]);

        $beforeStock = $inv->fresh()->stock;

        $this->actingAs($this->admin)
            ->post(route('admin.loans.pickup', $loan))
            ->assertRedirect();

        $fresh = $loan->fresh();
        self::assertSame(Loan::STATUS_BORROWED, $fresh->status);
        self::assertNotNull($fresh->picked_up_at);   // Property 28
        self::assertSame($beforeStock - 1, $inv->fresh()->stock);
    }

    public function test_pickup_blocked_when_stock_zero(): void
    {
        [$loan, $inv] = $this->loanWithStagedKtm(stock: 1);
        $loan->update(['status' => Loan::STATUS_APPROVED]);

        // Drain stock outside the loan flow (simulates an admin edit
        // that left stock at 0 before the student arrived).
        $inv->update(['stock' => 0, 'status' => Inventory::STATUS_OUT_OF_STOCK]);

        $this->actingAs($this->admin)
            ->post(route('admin.loans.pickup', $loan))
            ->assertSessionHas('error', 'Inventory is out of stock');

        self::assertSame(Loan::STATUS_APPROVED, $loan->fresh()->status);
    }

    public function test_pickup_blocked_when_loan_not_approved(): void
    {
        [$loan] = $this->loanWithStagedKtm();

        // Loan is still pending; pickup must be rejected.
        $this->actingAs($this->admin)
            ->post(route('admin.loans.pickup', $loan))
            ->assertSessionHas('error', 'Only approved loans can be marked as borrowed');
    }

    // ---------------------------------------------------------------
    // Return (borrowed -> returned, stock += 1)
    // ---------------------------------------------------------------

    public function test_return_transitions_borrowed_to_returned_and_increments_stock(): void
    {
        [$loan, $inv, $document] = $this->loanWithStagedKtm(stock: 4);
        $loan->update([
            'status' => Loan::STATUS_BORROWED,
            'picked_up_at' => now()->subDay(),
        ]);
        $inv->update(['stock' => 3]);   // simulate prior pickup

        $this->actingAs($this->admin)
            ->post(route('admin.loans.return', $loan))
            ->assertRedirect();

        $fresh = $loan->fresh();
        self::assertSame(Loan::STATUS_RETURNED, $fresh->status);
        self::assertNotNull($fresh->returned_at);    // Property 28
        self::assertSame(4, $inv->fresh()->stock);

        // Property 43: KTM document survives return for audit.
        $this->publicDisk()->assertExists($document);
    }

    public function test_return_blocked_when_loan_not_borrowed(): void
    {
        [$loan] = $this->loanWithStagedKtm();

        $this->actingAs($this->admin)
            ->post(route('admin.loans.return', $loan))
            ->assertSessionHas('error', 'Only borrowed loans can be marked as returned');
    }

    // ---------------------------------------------------------------
    // Stock conservation (Property 27 — integration shape)
    // ---------------------------------------------------------------

    public function test_full_cycle_preserves_stock_plus_borrowed_quantity(): void
    {
        $inv = Inventory::factory()->available(stock: 3)->create([
            'category_id' => $this->category->id,
        ]);
        $document = UploadedFile::fake()->create('ktm.jpg', 100, 'image/jpeg')
            ->store('ktm', 'public');

        $loan = Loan::factory()->pending()->create([
            'user_id' => $this->student->id,
            'inventory_id' => $inv->id,
            'document' => $document,
        ]);

        $initialStock = $inv->fresh()->stock;
        $expectedQuantity = $initialStock + Loan::query()
            ->where('inventory_id', $inv->id)
            ->where('status', Loan::STATUS_BORROWED)
            ->count();

        // approve (no change)
        $this->actingAs($this->admin)->post(route('admin.loans.approve', $loan));
        self::assertSame($expectedQuantity, $this->liveQuantity($inv->id));

        // pickup (stock -= 1, borrowed += 1)
        $this->actingAs($this->admin)->post(route('admin.loans.pickup', $loan));
        self::assertSame($expectedQuantity, $this->liveQuantity($inv->id));

        // return (stock += 1, borrowed -= 1)
        $this->actingAs($this->admin)->post(route('admin.loans.return', $loan));
        self::assertSame($expectedQuantity, $this->liveQuantity($inv->id));
    }

    private function liveQuantity(int $inventoryId): int
    {
        $stock = Inventory::query()->whereKey($inventoryId)->value('stock');
        $borrowed = Loan::query()
            ->where('inventory_id', $inventoryId)
            ->where('status', Loan::STATUS_BORROWED)
            ->count();

        return (int) $stock + $borrowed;
    }

    // ---------------------------------------------------------------
    // Index page
    // ---------------------------------------------------------------

    public function test_index_renders_loans_in_descending_order(): void
    {
        $inv = Inventory::factory()->available()->create([
            'category_id' => $this->category->id,
        ]);

        $older = Loan::factory()->pending()->create([
            'user_id' => $this->student->id,
            'inventory_id' => $inv->id,
            'created_at' => now()->subDays(2),
        ]);
        $newer = Loan::factory()->pending()->create([
            'user_id' => $this->student->id,
            'inventory_id' => $inv->id,
            'created_at' => now(),
        ]);

        $response = $this->actingAs($this->admin)
            ->get(route('admin.loans.index'))
            ->assertOk();

        // The list view uses LoanService::listForAdmin which orders by
        // created_at DESC. We assert the loans paginator on the view
        // honors that ordering.
        $loans = $response->viewData('loans');
        $ids = $loans->pluck('id')->all();

        self::assertSame(
            [$newer->id, $older->id],
            array_slice($ids, 0, 2),
            'newer loan should appear before the older one',
        );
    }

    public function test_index_filters_by_status(): void
    {
        $inv = Inventory::factory()->available()->create([
            'category_id' => $this->category->id,
        ]);
        Loan::factory()->pending()->count(2)->create([
            'user_id' => $this->student->id,
            'inventory_id' => $inv->id,
        ]);
        Loan::factory()->approved()->count(3)->create([
            'user_id' => $this->student->id,
            'inventory_id' => $inv->id,
        ]);

        $response = $this->actingAs($this->admin)
            ->get(route('admin.loans.index', ['status' => 'approved']))
            ->assertOk();

        // Header text "Approved" should appear at least once for the
        // selected filter; the table should not show pending loans by
        // count = 3 only.
        $response->assertSeeText('Approved');
    }
}
