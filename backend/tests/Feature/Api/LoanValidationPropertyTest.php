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
 * Feature: labventory-system, Property 25: Loan creation validation
 * rejects invalid submissions.
 *
 * For any loan submission, it is rejected (and no loan is persisted)
 * when:
 *   - inventory_id does not exist;
 *   - target inventory.stock = 0;
 *   - borrow_date < today;
 *   - return_date <= borrow_date;
 *   - document is wrong MIME or > 2 MB;
 *   - the student already has a pending loan for the same inventory.
 *
 * Validates: Requirements 8.2, 8.3, 8.4, 8.5, 8.6, 8.8.
 */
class LoanValidationPropertyTest extends TestCase
{
    use RefreshDatabase;
    use TestTrait;

    private User $student;

    private Inventory $inventory;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
        $this->student = User::factory()->student()->create();
        $this->inventory = Inventory::factory()->available(stock: 5)->create();
        Sanctum::actingAs($this->student, ['mobile']);
    }

    public function test_property_25a_unknown_inventory_id_is_rejected(): void
    {
        $this->forAll(Generator\choose(9000, 9999))
            ->then(function (int $unknownId): void {
                $response = $this->postJson('/api/loans', $this->validBody([
                    'inventory_id' => $unknownId,
                ]));

                $response->assertStatus(422)
                    ->assertJsonValidationErrors(['inventory_id']);
                self::assertSame(0, Loan::count());
            });
    }

    public function test_property_25b_out_of_stock_inventory_is_rejected(): void
    {
        $empty = Inventory::factory()->outOfStock()->create();

        $response = $this->postJson('/api/loans', $this->validBody([
            'inventory_id' => $empty->id,
        ]));

        $response->assertStatus(422)
            ->assertJsonPath('message', 'Inventory is out of stock');
        self::assertSame(0, Loan::count());
    }

    public function test_property_25c_borrow_date_in_the_past_is_rejected(): void
    {
        $this->forAll(Generator\choose(1, 30))
            ->then(function (int $daysAgo): void {
                $body = $this->validBody([
                    'borrow_date' => now()->subDays($daysAgo)->format('Y-m-d'),
                    'return_date' => now()->addDay()->format('Y-m-d'),
                ]);

                $this->postJson('/api/loans', $body)
                    ->assertStatus(422)
                    ->assertJsonValidationErrors(['borrow_date']);
            });
    }

    public function test_property_25d_return_date_not_after_borrow_is_rejected(): void
    {
        $this->forAll(Generator\choose(0, 5))
            ->then(function (int $offset): void {
                $borrow = now()->addDay();
                $return = $borrow->copy()->subDays($offset);

                $body = $this->validBody([
                    'borrow_date' => $borrow->format('Y-m-d'),
                    'return_date' => $return->format('Y-m-d'),
                ]);

                $this->postJson('/api/loans', $body)
                    ->assertStatus(422)
                    ->assertJsonValidationErrors(['return_date']);
            });
    }

    public function test_property_25e_invalid_document_mime_or_size_is_rejected(): void
    {
        $cases = [
            ['evil.exe', 'application/x-msdownload', 100],
            ['gigantic.pdf', 'application/pdf', 3 * 1024], // 3 MB > 2 MB
            ['video.mp4', 'video/mp4', 100],
        ];

        $this->forAll(Generator\elements(...$cases))
            ->then(function (array $case): void {
                [$name, $mime, $kb] = $case;
                $document = UploadedFile::fake()->create($name, $kb, $mime);

                $this->postJson('/api/loans', $this->validBody(['document' => $document]))
                    ->assertStatus(422)
                    ->assertJsonValidationErrors(['document']);
            });
    }

    public function test_property_25f_duplicate_pending_loan_is_rejected(): void
    {
        Loan::factory()->pending()->create([
            'user_id' => $this->student->id,
            'inventory_id' => $this->inventory->id,
        ]);

        $this->postJson('/api/loans', $this->validBody())
            ->assertStatus(422)
            ->assertJsonValidationErrors(['inventory_id']);

        // Sanity: still only one pending loan exists.
        self::assertSame(1, Loan::where('status', Loan::STATUS_PENDING)->count());
    }

    /**
     * Build a known-good loan submission body, optionally overriding
     * specific fields for the negative test.
     *
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function validBody(array $overrides = []): array
    {
        $document = $overrides['document']
            ?? UploadedFile::fake()->create('ktm.jpg', 100, 'image/jpeg');

        return array_merge([
            'inventory_id' => $this->inventory->id,
            'borrow_date' => now()->addDay()->format('Y-m-d'),
            'return_date' => now()->addDays(3)->format('Y-m-d'),
            'notes' => null,
            'document' => $document,
        ], $overrides, ['document' => $document]);
    }
}
