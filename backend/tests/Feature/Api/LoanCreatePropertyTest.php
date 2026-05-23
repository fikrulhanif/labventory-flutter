<?php

namespace Tests\Feature\Api;

use App\Models\Inventory;
use App\Models\Loan;
use App\Models\User;
use Eris\Generator;
use Eris\TestTrait;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Feature: labventory-system, Property 24: Loan creation produces a
 * pending loan owned by the requester.
 *
 * For any valid loan submission by an authenticated student, the
 * response is HTTP 201 with a LoanResource, and the persisted loan has
 * status = "pending", user_id matching the requester, and a document
 * path pointing to a file that exists on disk.
 *
 * Validates: Requirements 8.1, 8.9.
 */
class LoanCreatePropertyTest extends TestCase
{
    use RefreshDatabase;
    use TestTrait;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    public function test_property_24_creates_pending_loan_owned_by_requester(): void
    {
        $this->limitTo(8)->forAll(
            Generator\elements(['jpg', 'image/jpeg'], ['png', 'image/png'], ['pdf', 'application/pdf']),
        )->then(function (array $mime): void {
            [$ext, $mimeType] = $mime;

            $student = User::factory()->student()->create();
            $inventory = Inventory::factory()->available(stock: 5)->create();
            Sanctum::actingAs($student, ['mobile']);

            $document = UploadedFile::fake()
                ->create('ktm.'.$ext, 100, $mimeType);

            $borrow = now()->addDay()->format('Y-m-d');
            $return = now()->addDays(3)->format('Y-m-d');

            $response = $this->postJson('/api/loans', [
                'inventory_id' => $inventory->id,
                'borrow_date' => $borrow,
                'return_date' => $return,
                'notes' => 'For lab class',
                'document' => $document,
            ]);

            $response->assertCreated()
                ->assertJsonPath('success', true)
                ->assertJsonPath('data.status', Loan::STATUS_PENDING)
                ->assertJsonPath('data.borrow_date', $borrow)
                ->assertJsonPath('data.return_date', $return)
                ->assertJsonPath('data.user.id', $student->id)
                ->assertJsonPath('data.inventory.id', $inventory->id);

            // Persisted record state
            $loanId = (int) $response->json('data.id');
            $stored = Loan::findOrFail($loanId);
            self::assertSame(Loan::STATUS_PENDING, $stored->status);
            self::assertSame($student->id, $stored->user_id);
            self::assertSame($inventory->id, $stored->inventory_id);
            self::assertNotNull($stored->document);
            self::assertStringStartsWith('ktm/', $stored->document);
            self::assertTrue(Storage::disk('public')->exists($stored->document));
        });
    }
}
