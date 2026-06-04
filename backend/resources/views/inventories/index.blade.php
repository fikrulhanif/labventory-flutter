@extends('layouts.admin')

@section('title', 'Inventories')

@section('content')
    <div class="lv-page-header">
        <div>
            <h1>Inventories</h1>
            <p>Equipment catalog available for borrowing.</p>
        </div>
        <a href="{{ route('admin.inventories.create') }}" class="btn btn-primary btn-sm">
            <i class="bi bi-plus-lg me-1"></i> Add inventory
        </a>
    </div>

    <div class="lv-card">
        {{-- Filters --}}
        <div class="lv-card-header" style="background:#f0f3ff;">
            <form method="GET" class="lv-filters">
                <div class="lv-filter-field">
                    <label class="form-label" for="search">Search</label>
                    <input type="search" id="search" name="search" value="{{ $search }}"
                           class="form-control form-control-sm" placeholder="Name or code…">
                </div>
                <div class="lv-filter-field">
                    <label class="form-label" for="category_id">Category</label>
                    <select id="category_id" name="category_id" class="form-select form-select-sm">
                        <option value="">All categories</option>
                        @foreach ($categories as $cat)
                            <option value="{{ $cat->id }}" @selected((string)$selectedCategory===(string)$cat->id)>
                                {{ $cat->name }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <div class="lv-filter-field">
                    <label class="form-label" for="status">Status</label>
                    <select id="status" name="status" class="form-select form-select-sm">
                        <option value="">Any</option>
                        <option value="available" @selected($selectedStatus==='available')>Available</option>
                        <option value="out_of_stock" @selected($selectedStatus==='out_of_stock')>Out of stock</option>
                    </select>
                </div>
                <div style="display:flex;gap:8px;align-items:flex-end;">
                    <button class="btn btn-apply btn-sm" type="submit">
                        <i class="bi bi-funnel me-1"></i>Filter
                    </button>
                    @if ($search||$selectedCategory||$selectedStatus)
                        <a href="{{ route('admin.inventories.index') }}" class="btn btn-ghost btn-sm">Reset</a>
                    @endif
                </div>
            </form>
        </div>

        @if ($inventories->isEmpty())
            <div class="lv-empty">
                <i class="bi bi-boxes"></i>
                <p>No inventory items match these filters.</p>
            </div>
        @else
            <div style="overflow-x:auto;">
                <table class="lv-table">
                    <thead>
                        <tr>
                            <th>Item</th>
                            <th>Code</th>
                            <th>Category</th>
                            <th style="text-align:center;">Stock</th>
                            <th>Status</th>
                            <th style="text-align:right;">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($inventories as $inv)
                            <tr>
                                <td>
                                    <div style="display:flex;align-items:center;gap:10px;">
                                        @if ($inv->image_url)
                                            <img src="{{ $inv->image_url }}" alt=""
                                                 style="width:38px;height:38px;border-radius:10px;object-fit:cover;border:1px solid #e8eaf0;flex-shrink:0;">
                                        @else
                                            <div style="width:38px;height:38px;border-radius:10px;background:#f1f3f9;border:1px solid #e8eaf0;display:flex;align-items:center;justify-content:center;flex-shrink:0;">
                                                <i class="bi bi-image" style="color:#d1d5db;font-size:.9rem;"></i>
                                            </div>
                                        @endif
                                        <div>
                                            <div style="font-weight:600;">{{ $inv->name }}</div>
                                            <div style="font-size:.72rem;color:#9ca3af;">{{ \Illuminate\Support\Str::limit($inv->description, 55) }}</div>
                                        </div>
                                    </div>
                                </td>
                                <td><code>{{ $inv->code }}</code></td>
                                <td style="color:#6b7280;">{{ $inv->category?->name ?? '—' }}</td>
                                <td style="text-align:center;">
                                    <span style="font-weight:700;font-size:.9rem;">{{ $inv->stock }}</span>
                                </td>
                                <td>
                                    @if ($inv->status === 'available')
                                        <span class="lv-pill lv-pill-available">Available</span>
                                    @else
                                        <span class="lv-pill lv-pill-out">Out of stock</span>
                                    @endif
                                </td>
                                <td style="text-align:right;">
                                    <div class="lv-actions">
                                        <a href="{{ route('admin.inventories.show', $inv) }}" class="btn btn-ghost btn-sm" title="View">
                                            <i class="bi bi-eye"></i>
                                        </a>
                                        <a href="{{ route('admin.inventories.edit', $inv) }}" class="btn btn-ghost btn-sm" title="Edit">
                                            <i class="bi bi-pencil"></i>
                                        </a>
                                        <form method="POST" action="{{ route('admin.inventories.destroy', $inv) }}"
                                              class="d-inline"
                                              data-confirm="Delete '{{ $inv->name }}'? This cannot be undone."
                                              data-confirm-title="Delete inventory"
                                              data-confirm-yes="Yes, delete"
                                              data-confirm-tone="danger">                                            @csrf @method('DELETE')
                                            <button type="submit" class="btn btn-sm" style="background:#fef2f2;border:1px solid #fecaca;color:#dc2626;" title="Delete">
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

        @if ($inventories->hasPages())
            <div style="padding:14px 20px;border-top:1px solid #f0f2f8;">
                {{ $inventories->links() }}
            </div>
        @endif
    </div>
@endsection
