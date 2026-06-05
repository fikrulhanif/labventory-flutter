<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\InventoryResource;
use App\Http\Resources\LoanResource;
use App\Models\Inventory;
use App\Models\Loan;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

/**
 * Admin mobile operations — inventory identification by code.
 *
 * Backs the in-app QR / manual-lookup workflow for admin and laboran
 * users (Requirements 20, 21). Mounted under the route group
 * `auth:sanctum` + `role:admin,laboran`, so students and unauthenticated
 * clients can never reach these endpoints.
 *
 *   GET /api/admin/inventories/{code}         -> lookup()
 *   GET /api/admin/inventories/{code}/loans   -> loans()
 *
 * The {code} segment is matched exactly against inventories.code, the same
 * bare string encoded into the inventory QR (Requirements 15.1, 20.5).
 */
class AdminInventoryController extends Controller
{
    /**
     * Resolve an inventory item by its code (Requirement 20.1, 20.2).
     */
    public function lookup(string $code): JsonResponse
    {
        $inventory = Inventory::query()
            ->with('category')
            ->where('code', $code)
            ->first();

        if ($inventory === null) {
            return ApiResponse::notFound('Inventory code not found');
        }

        return ApiResponse::ok(
            ['inventory' => new InventoryResource($inventory)],
            'OK',
        );
    }

    /**
     * List the active loans (approved or borrowed) for the inventory that
     * carries the given code, ordered oldest-first so the admin can work
     * through them in arrival order (Requirement 21.1 — 21.4).
     */
    public function loans(string $code): JsonResponse
    {
        $inventory = Inventory::query()->where('code', $code)->first();

        if ($inventory === null) {
            return ApiResponse::notFound('Inventory code not found');
        }

        $loans = $inventory->loans()
            ->whereIn('status', [Loan::STATUS_APPROVED, Loan::STATUS_BORROWED])
            ->with(['user', 'inventory'])
            ->orderBy('created_at')
            ->get();

        return ApiResponse::ok([
            'inventory' => new InventoryResource($inventory->loadMissing('category')),
            'loans' => LoanResource::collection($loans),
        ], 'OK');
    }
}
