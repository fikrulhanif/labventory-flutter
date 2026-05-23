<?php

namespace Tests\Feature\Api;

use App\Models\Inventory;
use App\Models\User;
use Eris\Generator;
use Eris\TestTrait;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Feature: labventory-system, Property 44: File-bearing API responses
 * use absolute URLs.
 *
 * For any inventory record whose `image` and/or `qr_code` paths are
 * non-null, the API serializes them as `image_url` / `qr_url` strings
 * starting with http:// or https://.
 *
 * Validates: Requirement 18.5.
 *
 * Storage is faked with `Storage::fake('public')` so we never write real
 * files; the URL contract is what we test.
 */
class AbsoluteUrlPropertyTest extends TestCase
{
    use RefreshDatabase;
    use TestTrait;

    private const ABSOLUTE_URL = '/^https?:\/\//';

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
        Sanctum::actingAs(User::factory()->student()->create(), ['mobile']);
    }

    public function test_property_44_image_and_qr_urls_are_absolute(): void
    {
        $this->forAll(
            Generator\elements('jpg', 'png', 'webp'),
        )->then(function (string $ext): void {
            $inventory = Inventory::factory()->create([
                'image' => 'inventories/'.bin2hex(random_bytes(16)).'.'.$ext,
                'qr_code' => 'qr/'.bin2hex(random_bytes(16)).'.png',
            ]);

            $response = $this->getJson('/api/inventories/'.$inventory->id);
            $response->assertOk();

            $imageUrl = $response->json('data.image_url');
            $qrUrl = $response->json('data.qr_url');

            self::assertIsString($imageUrl);
            self::assertIsString($qrUrl);
            self::assertMatchesRegularExpression(self::ABSOLUTE_URL, $imageUrl);
            self::assertMatchesRegularExpression(self::ABSOLUTE_URL, $qrUrl);

            // Sanity: the relative path is preserved inside the URL
            self::assertStringContainsString($inventory->image, $imageUrl);
            self::assertStringContainsString($inventory->qr_code, $qrUrl);
        });
    }

    public function test_property_44_null_paths_serialize_to_null(): void
    {
        Inventory::factory()->create(['image' => null, 'qr_code' => null]);

        $response = $this->getJson('/api/inventories?per_page=1');
        $response->assertOk();

        $first = $response->json('data.items.0');
        self::assertNull($first['image_url']);
        self::assertNull($first['qr_url']);
    }
}
