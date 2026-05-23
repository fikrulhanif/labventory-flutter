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
 * Feature: labventory-system, Property 41: Stored filenames contain a
 * random token.
 *
 * Two uploads with identical bytes through the loan creation endpoint
 * produce two distinct persisted filenames, and each filename's
 * basename (sans extension) is at least 32 characters of random text
 * (Str::random(40)).
 *
 * Validates: Requirement 18.2.
 */
class FilenameRandomnessPropertyTest extends TestCase
{
    use RefreshDatabase;
    use TestTrait;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    public function test_property_41_two_uploads_produce_distinct_random_filenames(): void
    {
        $this->forAll(Generator\elements('jpg', 'png'))
            ->then(function (string $ext): void {
                $student = User::factory()->student()->create();
                Sanctum::actingAs($student, ['mobile']);

                $invA = Inventory::factory()->available(stock: 5)->create();
                $invB = Inventory::factory()->available(stock: 5)->create();

                $a = $this->submit($invA->id, 'ktm.'.$ext);
                $b = $this->submit($invB->id, 'ktm.'.$ext);

                self::assertNotSame($a, $b, 'expected distinct paths');

                foreach ([$a, $b] as $path) {
                    self::assertStringStartsWith('ktm/', $path);
                    $base = pathinfo($path, PATHINFO_FILENAME);
                    self::assertGreaterThanOrEqual(32, strlen($base));
                    self::assertMatchesRegularExpression('/^[A-Za-z0-9]+$/', $base);
                }
            });
    }

    private function submit(int $inventoryId, string $name): string
    {
        // Image::create() produces a real PNG/JPEG image so the framework's
        // MIME validator (which inspects file contents) accepts it.
        $document = UploadedFile::fake()->image($name, 100, 100);

        $response = $this->postJson('/api/loans', [
            'inventory_id' => $inventoryId,
            'borrow_date' => now()->addDay()->format('Y-m-d'),
            'return_date' => now()->addDays(2)->format('Y-m-d'),
            'document' => $document,
        ]);
        $response->assertCreated();

        $loanId = (int) $response->json('data.id');

        return Loan::findOrFail($loanId)->document;
    }
}
