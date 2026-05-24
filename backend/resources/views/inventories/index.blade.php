@extends('layouts.admin')

@section('title', 'Inventories')

@php
    $statusLabels = [
        'available' => ['label' => 'Available', 'tone' => 'success'],
        'out_of_stock' => ['label' => 'Out of stock', 'tone' => 'secondary'],
    ];
@endphp

@section('content')
    <div class="d-flex flex-wrap align-items-center justify-content-between mb-4 gap-3">
        <div>
            <h1 class="h4 mb-1 fw-semibold">Inventories</h1>
            <p class="text-muted small mb-0">Catalog of equipment available for borrowing.</p>
        </div>
        <a href="{{ route('admin.inventories.create') }}" class="btn btn-primary">
            <i class="bi bi-plus-lg me-1"></i> New inventory
        </a>
    </div>

    <div class="card border-0 shadow-sm">
        <div class="card-header bg-white py-3 border-0">
            <form method="GET" class="row g-2 align-items-end">
                <div class="col-12 col-md-5">
                    <label for="search" class="form-label small fw-medium mb-1">Search</label>
                    <input type="search"
                           id="search"
                           name="search"
                           value="{{ $search }}"
                           class="form-control"
                           placeholder="Name or code…">
                </div>
                <div class="col-6 col-md-3">
                    <label for="category_id" class="form-label small fw-medium mb-1">Category</label>
                    <select id="category_id" name="category_id" class="form-select">
                        <option value="">All categories</option>
                        @foreach ($categories as $category)
                            <option value="{{ $category->id }}"
                                @selected((string) $selectedCategory === (string) $category->id)>
                                {{ $category->name }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <div class="col-6 col-md-2">
                    <label for="status" class="form-label small fw-medium mb-1">Status</label>
                    <select id="status" name="status" class="form-select">
                        <option value="">Any</option>
                        <option value="available" @selected($selectedStatus === 'available')>Available</option>
                        <option value="out_of_stock" @selected($selectedStatus === 'out_of_stock')>Out of stock</option>
                    </select>
                </div>
                <div class="col-12 col-md-2 d-flex gap-2">
                    <button class="btn btn-light w-100" type="submit">Apply</button>
                    @if ($search !== '' || $selectedCategory || $selectedStatus)
                        <a href="{{ route('admin.inventories.index') }}" class="btn btn-link text-muted">Reset</a>
                    @endif
                </div>
            </form>
        </div>

        <div class="card-body p-0">
            @if ($inventories->isEmpty())
                <div class="text-center text-muted py-5">
                    <i class="bi bi-boxes display-6 d-block mb-2"></i>
                    No inventory items match these filters.
                </div>
            @else
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="ps-4">Item</th>
                                <th>Code</th>
                                <th>Category</th>
                                <th>Stock</th>
                                <th>Status</th>
                                <th class="pe-4 text-end">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($inventories as $inventory)
                                @php
                                    $status = $statusLabels[$inventory->status] ?? ['label' => $inventory->status, 'tone' => 'secondary'];
                                @endphp
                                <tr>
                                    <td class="ps-4">
                                        <div class="d-flex align-items-center gap-3">
                                            @if ($inventory->image_url)
                                                <img src="{{ $inventory->image_url }}"
                                                     alt=""
                                                     class="rounded border"
                                                     style="width:40px;height:40px;object-fit:cover;">
                                            @else
                                                <div class="rounded border bg-light d-flex align-items-center justify-content-center"
                                                     style="width:40px;height:40px;">
                                                    <i class="bi bi-image text-muted"></i>
                                                </div>
                                            @endif
                                            <div>
                                                <div class="fw-medium">{{ $inventory->name }}</div>
                                                <div class="text-muted small">
                                                    {{ \Illuminate\Support\Str::limit($inventory->description, 60) }}
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td><code class="small">{{ $inventory->code }}</code></td>
                                    <td>{{ $inventory->category?->name ?? '-' }}</td>
                                    <td>{{ $inventory->stock }}</td>
                                    <td>
                                        <span class="badge text-bg-{{ $status['tone'] }} text-uppercase">
                                            {{ $status['label'] }}
                                        </span>
                                    </td>
                                    <td class="pe-4 text-end">
                                        <a href="{{ route('admin.inventories.show', $inventory) }}"
                                           class="btn btn-sm btn-light">
                                            <i class="bi bi-eye"></i>
                                        </a>
                                        <a href="{{ route('admin.inventories.edit', $inventory) }}"
                                           class="btn btn-sm btn-light">
                                            <i class="bi bi-pencil"></i>
                                        </a>
                                        <form method="POST"
                                              action="{{ route('admin.inventories.destroy', $inventory) }}"
                                              class="d-inline"
                                              onsubmit="return confirm('Delete this inventory item? This cannot be undone.');">
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

        @if ($inventories->hasPages())
            <div class="card-footer bg-white border-0">
                {{ $inventories->links() }}
            </div>
        @endif
    </div>
@endsection
