@extends('layouts.admin')

@section('title', $inventory->name)

@php
    $statusLabel = $inventory->status === 'available' ? 'Available' : 'Out of stock';
    $statusTone = $inventory->status === 'available' ? 'success' : 'secondary';
@endphp

@section('content')
    <nav aria-label="breadcrumb" class="mb-3">
        <ol class="breadcrumb small mb-0">
            <li class="breadcrumb-item"><a href="{{ route('admin.inventories.index') }}">Inventories</a></li>
            <li class="breadcrumb-item active" aria-current="page">{{ $inventory->code }}</li>
        </ol>
    </nav>

    <div class="d-flex flex-wrap align-items-center justify-content-between mb-4 gap-2">
        <div>
            <h1 class="h4 mb-1 fw-semibold">{{ $inventory->name }}</h1>
            <p class="text-muted small mb-0">
                <code>{{ $inventory->code }}</code> &middot; {{ $inventory->category?->name ?? '—' }}
            </p>
        </div>
        <div class="d-flex gap-2">
            <a href="{{ route('admin.inventories.edit', $inventory) }}" class="btn btn-light">
                <i class="bi bi-pencil me-1"></i> Edit
            </a>
            <form method="POST"
                  action="{{ route('admin.inventories.destroy', $inventory) }}"
                  onsubmit="return confirm('Delete this inventory item? This cannot be undone.');">
                @csrf
                @method('DELETE')
                <button type="submit" class="btn btn-outline-danger">
                    <i class="bi bi-trash me-1"></i> Delete
                </button>
            </form>
        </div>
    </div>

    <div class="row g-4">
        <div class="col-12 col-lg-8">
            <div class="card border-0 shadow-sm">
                <div class="card-body p-4">
                    <div class="row g-4">
                        <div class="col-12 col-md-5">
                            @if ($inventory->image_url)
                                <img src="{{ $inventory->image_url }}"
                                     alt="{{ $inventory->name }}"
                                     class="img-fluid rounded border w-100"
                                     style="object-fit:cover;max-height:280px;">
                            @else
                                <div class="border rounded bg-light d-flex align-items-center justify-content-center"
                                     style="height:240px;">
                                    <i class="bi bi-image text-muted display-5"></i>
                                </div>
                            @endif
                        </div>
                        <div class="col-12 col-md-7">
                            <div class="mb-3">
                                <span class="badge text-bg-{{ $statusTone }} text-uppercase me-2">
                                    {{ $statusLabel }}
                                </span>
                                <span class="text-muted small">Stock: <strong>{{ $inventory->stock }}</strong></span>
                            </div>
                            <h2 class="h6 fw-semibold">Description</h2>
                            <p class="text-muted">
                                {{ $inventory->description ?: 'No description provided.' }}
                            </p>
                            <hr>
                            <dl class="row small mb-0">
                                <dt class="col-sm-4 text-muted">Created</dt>
                                <dd class="col-sm-8">{{ $inventory->created_at?->toDayDateTimeString() }}</dd>
                                <dt class="col-sm-4 text-muted">Last updated</dt>
                                <dd class="col-sm-8">{{ $inventory->updated_at?->toDayDateTimeString() }}</dd>
                            </dl>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-12 col-lg-4">
            <div class="card border-0 shadow-sm">
                <div class="card-body p-4 text-center">
                    <h2 class="h6 fw-semibold mb-3">QR code</h2>
                    @if ($inventory->qr_url)
                        <img src="{{ $inventory->qr_url }}"
                             alt="QR for {{ $inventory->code }}"
                             class="img-fluid border rounded mb-3"
                             style="max-width:200px;">
                        <a href="{{ $inventory->qr_url }}"
                           download="{{ $inventory->code }}.png"
                           class="btn btn-light w-100">
                            <i class="bi bi-download me-1"></i> Download QR
                        </a>
                    @else
                        <div class="border rounded bg-light d-flex align-items-center justify-content-center mb-3"
                             style="height:200px;">
                            <i class="bi bi-qr-code display-5 text-muted"></i>
                        </div>
                        <p class="text-muted small mb-0">QR code is generated automatically when QR feature lands.</p>
                    @endif
                </div>
            </div>
        </div>
    </div>
@endsection
