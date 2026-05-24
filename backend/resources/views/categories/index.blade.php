@extends('layouts.admin')

@section('title', 'Categories')

@section('content')
    <div class="d-flex flex-wrap align-items-center justify-content-between mb-4 gap-3">
        <div>
            <h1 class="h4 mb-1 fw-semibold">Categories</h1>
            <p class="text-muted small mb-0">Group inventory items by type.</p>
        </div>
        <a href="{{ route('admin.categories.create') }}" class="btn btn-primary">
            <i class="bi bi-plus-lg me-1"></i> New category
        </a>
    </div>

    <div class="card border-0 shadow-sm">
        <div class="card-header bg-white py-3 border-0">
            <form method="GET" class="d-flex" role="search">
                <input type="search"
                       name="search"
                       value="{{ $search }}"
                       class="form-control"
                       placeholder="Search by name…">
                @if ($search !== '')
                    <a href="{{ route('admin.categories.index') }}" class="btn btn-light ms-2">Clear</a>
                @endif
            </form>
        </div>

        <div class="card-body p-0">
            @if ($categories->isEmpty())
                <div class="text-center text-muted py-5">
                    <i class="bi bi-tags display-6 d-block mb-2"></i>
                    No categories yet.
                </div>
            @else
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="ps-4">Name</th>
                                <th>Inventories</th>
                                <th>Created</th>
                                <th class="pe-4 text-end">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($categories as $category)
                                <tr>
                                    <td class="ps-4 fw-medium">{{ $category->name }}</td>
                                    <td>
                                        <span class="badge text-bg-light border">
                                            {{ $category->inventories_count }}
                                        </span>
                                    </td>
                                    <td class="text-muted small">{{ $category->created_at?->toDateString() }}</td>
                                    <td class="pe-4 text-end">
                                        <a href="{{ route('admin.categories.edit', $category) }}"
                                           class="btn btn-sm btn-light">
                                            <i class="bi bi-pencil"></i>
                                        </a>
                                        <form method="POST"
                                              action="{{ route('admin.categories.destroy', $category) }}"
                                              class="d-inline"
                                              onsubmit="return confirm('Delete this category? This cannot be undone.');">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="btn btn-sm btn-outline-danger">
                                                <i class="bi bi-trash"></i>
                                            </button>
                                        </form>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endif
        </div>

        @if ($categories->hasPages())
            <div class="card-footer bg-white border-0">
                {{ $categories->links() }}
            </div>
        @endif
    </div>
@endsection
