<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Http\Requests\Web\Inventory\StoreInventoryRequest;
use App\Http\Requests\Web\Inventory\UpdateInventoryRequest;
use App\Models\Category;
use App\Models\Inventory;
use App\Services\InventoryService;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

/**
 * CRUD for inventory items.
 *
 *   GET    /admin/inventories            index   — search + filters + paginated table
 *   GET    /admin/inventories/create     create
 *   POST   /admin/inventories            store   — image upload optional
 *   GET    /admin/inventories/{i}        show    — detail with QR preview
 *   GET    /admin/inventories/{i}/edit   edit
 *   PUT    /admin/inventories/{i}        update  — replaces image when provided
 *   DELETE /admin/inventories/{i}        destroy — guarded by active loans (Req 6.7, 6.8)
 *
 * All business logic (image storage, status derivation, file cleanup)
 * lives in InventoryService. The controller only adapts HTTP input/output.
 *
 * Validates Requirements 6.1 — 6.9, 18.3.
 */
class InventoryController extends Controller
{
    public function __construct(private readonly InventoryService $inventoryService)
    {
    }

    public function index(Request $request): View
    {
        $page = $this->inventoryService->list([
            'search' => $request->query('search'),
            'category_id' => $request->query('category_id'),
            'status' => $request->query('status'),
            'per_page' => $request->query('per_page', 15),
        ]);

        $page = $page->withQueryString();

        $categories = Category::query()->orderBy('name')->get();

        return view('inventories.index', [
            'inventories' => $page,
            'categories' => $categories,
            'search' => (string) $request->query('search', ''),
            'selectedCategory' => $request->query('category_id'),
            'selectedStatus' => $request->query('status'),
        ]);
    }

    public function create(): View
    {
        return view('inventories.create', [
            'categories' => Category::query()->orderBy('name')->get(),
            'inventory' => null,
        ]);
    }

    public function store(StoreInventoryRequest $request): RedirectResponse
    {
        $this->inventoryService->create(
            $request->safe()->only(['category_id', 'name', 'code', 'stock', 'description']),
            $request->file('image'),
        );

        return redirect()
            ->route('admin.inventories.index')
            ->with('success', 'Inventory item created.');
    }

    public function show(Inventory $inventory): View
    {
        $inventory->load('category');

        return view('inventories.show', [
            'inventory' => $inventory,
        ]);
    }

    public function edit(Inventory $inventory): View
    {
        return view('inventories.edit', [
            'categories' => Category::query()->orderBy('name')->get(),
            'inventory' => $inventory,
        ]);
    }

    public function update(UpdateInventoryRequest $request, Inventory $inventory): RedirectResponse
    {
        $this->inventoryService->update(
            $inventory,
            $request->safe()->only(['category_id', 'name', 'code', 'stock', 'description']),
            $request->file('image'),
        );

        return redirect()
            ->route('admin.inventories.index')
            ->with('success', 'Inventory item updated.');
    }

    public function destroy(Inventory $inventory): RedirectResponse
    {
        // Active-loan guard (Requirements 6.7, 6.8). The service layer
        // performs the file cleanup once we clear this check.
        if ($inventory->activeLoans()->exists()) {
            return back()->with(
                'error',
                'Cannot delete inventory with active loans',
            );
        }

        $this->inventoryService->delete($inventory);

        return redirect()
            ->route('admin.inventories.index')
            ->with('success', 'Inventory item deleted.');
    }
}
