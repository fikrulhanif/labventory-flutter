<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Http\Requests\Web\Category\StoreCategoryRequest;
use App\Http\Requests\Web\Category\UpdateCategoryRequest;
use App\Models\Category;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

/**
 * CRUD for inventory categories.
 *
 *   GET    /admin/categories            index
 *   GET    /admin/categories/create     create
 *   POST   /admin/categories            store
 *   GET    /admin/categories/{c}/edit   edit
 *   PUT    /admin/categories/{c}        update
 *   DELETE /admin/categories/{c}        destroy
 *
 * Validates Requirements 5.1 — 5.6.
 */
class CategoryController extends Controller
{
    public function index(Request $request): View
    {
        $search = trim((string) $request->query('search', ''));

        $query = Category::query()->withCount('inventories');

        if ($search !== '') {
            $query->where('name', 'like', "%{$search}%");
        }

        $categories = $query->orderBy('name')->paginate(15)->withQueryString();

        return view('categories.index', [
            'categories' => $categories,
            'search' => $search,
        ]);
    }

    public function create(): View
    {
        return view('categories.create');
    }

    public function store(StoreCategoryRequest $request): RedirectResponse
    {
        Category::create($request->validated());

        return redirect()
            ->route('admin.categories.index')
            ->with('success', 'Category created.');
    }

    public function edit(Category $category): View
    {
        return view('categories.edit', ['category' => $category]);
    }

    public function update(UpdateCategoryRequest $request, Category $category): RedirectResponse
    {
        $originalCreatedAt = $category->created_at;

        $category->fill($request->validated());
        $category->save();

        // Defensive: restore original created_at if Eloquent ever
        // accidentally touches it (Requirement 5.4).
        if ($originalCreatedAt !== null && ! $category->created_at?->equalTo($originalCreatedAt)) {
            $category->created_at = $originalCreatedAt;
            $category->saveQuietly();
        }

        return redirect()
            ->route('admin.categories.index')
            ->with('success', 'Category updated.');
    }

    public function destroy(Category $category): RedirectResponse
    {
        if ($category->inventories()->exists()) {
            return back()->with(
                'error',
                'Cannot delete a category that still contains inventory',
            );
        }

        $category->delete();

        return redirect()
            ->route('admin.categories.index')
            ->with('success', 'Category deleted.');
    }
}
