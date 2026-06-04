@extends('layouts.admin')

@section('title', 'Categories')

@section('content')
    <div class="lv-page-header">
        <div>
            <h1>Categories</h1>
            <p>Group inventory items by type.</p>
        </div>
        <a href="{{ route('admin.categories.create') }}" class="btn btn-primary btn-sm">
            <i class="bi bi-plus-lg me-1"></i> Add category
        </a>
    </div>

    <div class="lv-card">
        <div class="lv-card-header" style="background:#f8f9ff;">
            <form method="GET" class="lv-filters">
                <div class="lv-filter-field" style="flex:1;">
                    <label class="form-label" for="search">Search</label>
                    <input type="search" id="search" name="search" value="{{ $search }}"
                           class="form-control form-control-sm" placeholder="Category name…">
                </div>
                <div style="display:flex;gap:8px;align-items:flex-end;">
                    <button class="btn btn-apply btn-sm" type="submit">
                        <i class="bi bi-search me-1"></i>Search
                    </button>
                    @if ($search !== '')
                        <a href="{{ route('admin.categories.index') }}" class="btn btn-ghost btn-sm">Clear</a>
                    @endif
                </div>
            </form>
        </div>

        @if ($categories->isEmpty())
            <div class="lv-empty">
                <i class="bi bi-tags"></i>
                <p>No categories yet. Create the first one.</p>
            </div>
        @else
            <div style="overflow-x:auto;">
                <table class="lv-table">
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th style="text-align:center;">Inventories</th>
                            <th>Created</th>
                            <th style="text-align:right;">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($categories as $category)
                            <tr>
                                <td style="font-weight:600;">{{ $category->name }}</td>
                                <td style="text-align:center;">
                                    <span style="font-weight:700;font-size:.88rem;color:{{ $category->inventories_count > 0 ? '#6366f1' : '#9ca3af' }}">
                                        {{ $category->inventories_count }}
                                    </span>
                                </td>
                                <td style="font-size:.78rem;color:#9ca3af;">
                                    {{ $category->created_at?->format('d M Y') }}
                                </td>
                                <td style="text-align:right;">
                                    <div class="lv-actions">
                                        <a href="{{ route('admin.categories.edit', $category) }}"
                                           class="btn btn-ghost btn-sm" title="Edit">
                                            <i class="bi bi-pencil"></i>
                                        </a>
                                        <form method="POST" action="{{ route('admin.categories.destroy', $category) }}"
                                              class="d-inline"
                                              data-confirm="Delete '{{ $category->name }}'? This cannot be undone."
                                              data-confirm-title="Delete category"
                                              data-confirm-yes="Yes, delete"
                                              data-confirm-tone="danger">                                            @csrf @method('DELETE')
                                            <button type="submit" class="btn btn-sm"
                                                    style="background:#fef2f2;border:1px solid #fecaca;color:#dc2626;">
                                                <i class="bi bi-trash"></i>
                                            </button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif

        @if ($categories->hasPages())
            <div style="padding:14px 20px;border-top:1px solid #f0f2f8;">
                {{ $categories->links() }}
            </div>
        @endif
    </div>
@endsection
