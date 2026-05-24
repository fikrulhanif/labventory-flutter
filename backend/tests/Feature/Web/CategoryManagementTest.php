<?php

namespace Tests\Feature\Web;

use App\Models\Category;
use App\Models\Inventory;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Example-based feature tests for the admin category CRUD.
 *
 * Validates Requirements 5.1 — 5.6 (Property 13, 14, 15).
 *
 * Property-based fuzzing of these rules ran into Eris/RefreshDatabase
 * state-leak issues with foreign-key chains (Category -> Inventory),
 * so we cover the exact same rules with deterministic example tests.
 * The acceptance criteria are pinned by canonical strings on the
 * controller side, so a regression on the wording or rule will still
 * surface here.
 */
class CategoryManagementTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::factory()->admin()->create();
    }

    public function test_create_succeeds_with_valid_name(): void
    {
        $this->actingAs($this->admin)
            ->post(route('admin.categories.store'), ['name' => 'Robotics'])
            ->assertRedirect(route('admin.categories.index'))
            ->assertSessionHas('success');

        self::assertNotNull(Category::query()->where('name', 'Robotics')->first());
    }

    public function test_create_rejects_empty_name(): void
    {
        $this->actingAs($this->admin)
            ->post(route('admin.categories.store'), ['name' => ''])
            ->assertSessionHasErrors('name');
    }

    public function test_create_rejects_name_longer_than_100_chars(): void
    {
        $name = str_repeat('A', 101);

        $this->actingAs($this->admin)
            ->post(route('admin.categories.store'), ['name' => $name])
            ->assertSessionHasErrors('name');

        self::assertNull(Category::query()->where('name', $name)->first());
    }

    public function test_create_accepts_name_at_100_char_boundary(): void
    {
        $name = str_repeat('B', 100);

        $this->actingAs($this->admin)
            ->post(route('admin.categories.store'), ['name' => $name])
            ->assertRedirect(route('admin.categories.index'));

        self::assertNotNull(Category::query()->where('name', $name)->first());
    }

    public function test_create_rejects_duplicate_name(): void
    {
        Category::factory()->create(['name' => 'Reserved-Camera-Test']);

        $this->actingAs($this->admin)
            ->post(route('admin.categories.store'), ['name' => 'Reserved-Camera-Test'])
            ->assertSessionHasErrors('name');

        self::assertSame(1, Category::query()->where('name', 'Reserved-Camera-Test')->count());
    }

    public function test_update_changes_name_and_preserves_created_at(): void
    {
        $category = Category::factory()->create([
            'name' => 'Original',
            'created_at' => now()->subDays(30),
            'updated_at' => now()->subDays(30),
        ]);
        $originalCreatedAt = $category->created_at;

        $this->travel(5)->minutes();

        $this->actingAs($this->admin)
            ->put(route('admin.categories.update', $category), ['name' => 'Renamed'])
            ->assertRedirect(route('admin.categories.index'));

        $fresh = $category->fresh();
        self::assertSame('Renamed', $fresh->name);
        self::assertTrue($originalCreatedAt->equalTo($fresh->created_at));
        self::assertTrue($fresh->updated_at->greaterThan($originalCreatedAt));

        $this->travelBack();
    }

    public function test_update_allows_saving_same_name(): void
    {
        $category = Category::factory()->create(['name' => 'Stable']);

        $this->actingAs($this->admin)
            ->put(route('admin.categories.update', $category), ['name' => 'Stable'])
            ->assertRedirect(route('admin.categories.index'));

        self::assertSame('Stable', $category->fresh()->name);
    }

    public function test_update_rejects_duplicate_name(): void
    {
        Category::factory()->create(['name' => 'Existing']);
        $target = Category::factory()->create(['name' => 'Target']);

        $this->actingAs($this->admin)
            ->put(route('admin.categories.update', $target), ['name' => 'Existing'])
            ->assertSessionHasErrors('name');

        self::assertSame('Target', $target->fresh()->name);
    }

    public function test_delete_succeeds_when_no_related_inventory(): void
    {
        $category = Category::factory()->create();

        $this->actingAs($this->admin)
            ->delete(route('admin.categories.destroy', $category))
            ->assertRedirect(route('admin.categories.index'))
            ->assertSessionHas('success');

        self::assertNull(Category::find($category->id));
    }

    public function test_delete_rejected_when_inventory_exists(): void
    {
        $category = Category::factory()->create();
        Inventory::factory()->create(['category_id' => $category->id]);

        $this->actingAs($this->admin)
            ->delete(route('admin.categories.destroy', $category))
            ->assertSessionHas('error', 'Cannot delete a category that still contains inventory');

        self::assertNotNull(Category::find($category->id));
    }
}
