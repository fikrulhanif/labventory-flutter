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
 * Feature: labventory-system, Property 42: KTM document access control.
 *
 * For any loan and authenticated user, GET /api/loans/{id}/document:
 *   - returns the file iff user.id == loan.user_id OR user.role in {admin, laboran};
 *   - returns 403 otherwise.
 *
 * Validates: Requirement 18.6.
 */
class KtmAccessPropertyTest extends TestCase
{
    use RefreshDatabase;
    use TestTrait;

    private User $owner;

    private User $otherStudent;

    private User $admin;

    private User $laboran;

    private Loan $loan;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');

        $this->owner = User::factory()->student()->create();
        $this->otherStudent = User::factory()->student()->create();
        $this->admin = User::factory()->admin()->create();
        $this->laboran = User::factory()->laboran()->create();

        $inventory = Inventory::factory()->create();

        // Stage a KTM file so the streaming controller has something to
        // serve when access is granted.
        $document = UploadedFile::fake()->create('ktm.jpg', 100, 'image/jpeg');
        $path = $document->store('ktm', 'public');

        $this->loan = Loan::factory()->pending()->create([
            'user_id' => $this->owner->id,
            'inventory_id' => $inventory->id,
            'document' => $path,
        ]);
    }

    public function test_property_42_owner_and_staff_can_download(): void
    {
        $this->forAll(Generator\elements('owner', 'admin', 'laboran'))
            ->then(function (string $who): void {
                $user = match ($who) {
                    'owner' => $this->owner,
                    'admin' => $this->admin,
                    'laboran' => $this->laboran,
                };

                Sanctum::actingAs($user, ['mobile']);

                $response = $this->get('/api/loans/'.$this->loan->id.'/document', [
                    'Accept' => 'application/json',
                ]);
                $response->assertOk();
                $this->flushHeaders();
            });
    }

    public function test_property_42_other_student_is_forbidden(): void
    {
        Sanctum::actingAs($this->otherStudent, ['mobile']);

        $this->get('/api/loans/'.$this->loan->id.'/document', [
            'Accept' => 'application/json',
        ])
            ->assertStatus(403)
            ->assertJsonPath('message', 'Forbidden');
    }
}
