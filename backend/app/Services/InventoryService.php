<?php

namespace App\Services;

use App\Models\Inventory;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * InventoryService owns the inventory aggregate:
 *
 *   - CRUD with image upload to the public disk under "inventories/"
 *   - Status derivation: `available` iff stock > 0, `out_of_stock` iff stock = 0
 *   - Stock mutations (decrement/increment) wrapped in DB::transaction +
 *     SELECT FOR UPDATE so the stock conservation invariant (Property 27)
 *     holds under concurrent admin actions.
 *
 * Validates Requirements 6.1, 6.6, 6.7, 6.9, 7.1 — 7.7, 10.6, 18.2, 18.3.
 */
class InventoryService
{
    public const IMAGE_DISK = 'public';

    public const IMAGE_DIR = 'inventories';

    public const DEFAULT_PAGE_SIZE = 15;

    public const MAX_PAGE_SIZE = 50;

    /**
     * Paginated inventory list. Filters are optional and combinable.
     *
     * @param  array{search?: string|null, category_id?: int|string|null, status?: string|null, per_page?: int|string|null}  $filters
     */
    public function list(array $filters = []): LengthAwarePaginator
    {
        $query = Inventory::query()->with('category');

        $this->applyFilters($query, $filters);

        $perPage = $this->resolvePerPage($filters['per_page'] ?? null);

        return $query->orderBy('name')->paginate($perPage);
    }

    /**
     * @return Inventory
     */
    public function find(int $id): Inventory
    {
        return Inventory::with('category')->findOrFail($id);
    }

    /**
     * Create a new inventory record. Persists the optional image and
     * recomputes the derived `status` field (Requirement 6.9).
     *
     * @param  array<string, mixed>  $data
     */
    public function create(array $data, ?UploadedFile $image = null): Inventory
    {
        return DB::transaction(function () use ($data, $image) {
            $attributes = $this->extractWritable($data);

            if ($image !== null) {
                $attributes['image'] = $this->storeImage($image);
            }

            $inventory = Inventory::create($attributes);
            $this->recomputeStatus($inventory);

            return $inventory->fresh('category');
        });
    }

    /**
     * Update an existing inventory record. Replaces the image when a new
     * one is provided (the previous file is removed best-effort).
     *
     * @param  array<string, mixed>  $data
     */
    public function update(Inventory $inventory, array $data, ?UploadedFile $image = null): Inventory
    {
        return DB::transaction(function () use ($inventory, $data, $image) {
            $attributes = $this->extractWritable($data);

            if ($image !== null) {
                $oldPath = $inventory->image;
                $attributes['image'] = $this->storeImage($image);
                $inventory->fill($attributes);
                $inventory->save();
                $this->deleteFromPublicDisk($oldPath);
            } else {
                $inventory->fill($attributes);
                $inventory->save();
            }

            $this->recomputeStatus($inventory);

            return $inventory->fresh('category');
        });
    }

    /**
     * Delete an inventory record AND its associated image / QR files.
     *
     * The caller is responsible for the active-loan guard (Requirement 6.8);
     * this method just performs the deletion and best-effort file cleanup.
     */
    public function delete(Inventory $inventory): void
    {
        DB::transaction(function () use ($inventory): void {
            $imagePath = $inventory->image;
            $qrPath = $inventory->qr_code;
            $inventory->delete();
            $this->deleteFromPublicDisk($imagePath);
            $this->deleteFromPublicDisk($qrPath);
        });
    }

    /**
     * Recompute `status` from `stock` and persist when it has changed.
     *
     *   stock > 0  -> "available"
     *   stock == 0 -> "out_of_stock"
     *
     * Idempotent: calling this method twice in a row is a no-op on the
     * second call (Property 16).
     */
    public function recomputeStatus(Inventory $inventory): void
    {
        $expected = $inventory->stock > 0
            ? Inventory::STATUS_AVAILABLE
            : Inventory::STATUS_OUT_OF_STOCK;

        if ($inventory->status !== $expected) {
            $inventory->status = $expected;
            $inventory->save();
        }
    }

    /**
     * Decrement stock atomically with row-level locking so concurrent
     * pickup actions can never produce negative stock.
     *
     * Returns the post-decrement stock value. The caller (LoanService)
     * is expected to wrap this call in its own outer transaction.
     */
    public function decrementStock(int $inventoryId): int
    {
        return DB::transaction(function () use ($inventoryId): int {
            /** @var Inventory $inventory */
            $inventory = Inventory::query()
                ->lockForUpdate()
                ->findOrFail($inventoryId);

            if ($inventory->stock <= 0) {
                throw new \App\Exceptions\OutOfStockException();
            }

            $inventory->stock -= 1;
            $inventory->save();
            $this->recomputeStatus($inventory);

            return $inventory->stock;
        });
    }

    /**
     * Increment stock atomically with row-level locking. Used by loan
     * return.
     */
    public function incrementStock(int $inventoryId): int
    {
        return DB::transaction(function () use ($inventoryId): int {
            /** @var Inventory $inventory */
            $inventory = Inventory::query()
                ->lockForUpdate()
                ->findOrFail($inventoryId);

            $inventory->stock += 1;
            $inventory->save();
            $this->recomputeStatus($inventory);

            return $inventory->stock;
        });
    }

    // ------------------------------------------------------------------
    // Internal helpers
    // ------------------------------------------------------------------

    /**
     * @param  Builder<Inventory>  $query
     * @param  array<string, mixed>  $filters
     */
    private function applyFilters(Builder $query, array $filters): void
    {
        $search = isset($filters['search']) ? trim((string) $filters['search']) : '';
        if ($search !== '') {
            $query->where(function (Builder $inner) use ($search): void {
                $inner->where('name', 'like', "%{$search}%")
                    ->orWhere('code', 'like', "%{$search}%");
            });
        }

        if (isset($filters['category_id']) && $filters['category_id'] !== null && $filters['category_id'] !== '') {
            $query->where('category_id', (int) $filters['category_id']);
        }

        if (isset($filters['status']) && in_array($filters['status'], [
            Inventory::STATUS_AVAILABLE,
            Inventory::STATUS_OUT_OF_STOCK,
        ], true)) {
            $query->where('status', $filters['status']);
        }
    }

    /**
     * @param  int|string|null  $raw
     */
    private function resolvePerPage($raw): int
    {
        if ($raw === null || $raw === '') {
            return self::DEFAULT_PAGE_SIZE;
        }

        $value = (int) $raw;
        if ($value < 1) {
            return self::DEFAULT_PAGE_SIZE;
        }

        return min($value, self::MAX_PAGE_SIZE);
    }

    /**
     * Drop client-controlled fields that must never be assigned directly
     * (e.g. status — derived from stock; qr_code — owned by QrCodeService).
     *
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    private function extractWritable(array $data): array
    {
        return array_intersect_key($data, array_flip([
            'category_id',
            'name',
            'code',
            'stock',
            'description',
        ]));
    }

    /**
     * Persist an uploaded image with a randomized filename so identical
     * bytes uploaded twice do not collide (Requirement 18.2). Returns
     * the relative path stored on the inventory record (e.g. "inventories/abc.jpg").
     */
    private function storeImage(UploadedFile $file): string
    {
        $extension = strtolower($file->getClientOriginalExtension())
            ?: $file->guessExtension()
            ?: 'bin';
        $filename = Str::random(40).'.'.$extension;

        return $file->storeAs(self::IMAGE_DIR, $filename, self::IMAGE_DISK);
    }

    /**
     * Best-effort delete: log on failure but do not bubble up so the
     * inventory row delete still succeeds (Requirement 18.3 file cleanup).
     */
    private function deleteFromPublicDisk(?string $relativePath): void
    {
        if ($relativePath === null || $relativePath === '') {
            return;
        }

        try {
            Storage::disk(self::IMAGE_DISK)->delete($relativePath);
        } catch (\Throwable $e) {
            Log::warning('Failed to delete public-disk file', [
                'path' => $relativePath,
                'error' => $e->getMessage(),
            ]);
        }
    }
}
