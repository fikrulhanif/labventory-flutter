<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\InventoryResource;
use App\Services\InventoryService;
use App\Support\ApiResponse;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Mobile-facing inventory endpoints.
 *
 *   GET /api/inventories          — paginated list with filters
 *   GET /api/inventories/{id}     — detail
 *
 * Validates Requirements 7.1 — 7.7.
 */
class InventoryController extends Controller
{
    public function __construct(private readonly InventoryService $inventory)
    {
    }

    public function index(Request $request): JsonResponse
    {
        $page = $this->inventory->list([
            'search' => $request->query('search'),
            'category_id' => $request->query('category_id'),
            'status' => $request->query('status'),
            'per_page' => $request->query('per_page'),
        ]);

        // Wrap the paginator with InventoryResource so each item is
        // serialized correctly; ApiResponse will lift the items + meta.
        $collection = InventoryResource::collection($page);

        return ApiResponse::ok($collection, 'OK');
    }

    public function show(int $id): JsonResponse
    {
        try {
            $inventory = $this->inventory->find($id);
        } catch (ModelNotFoundException) {
            return ApiResponse::notFound('Inventory not found');
        }

        return ApiResponse::ok(
            new InventoryResource($inventory),
            'OK',
        );
    }
}
