@extends('layouts.admin')

@section('title', $inventory->name)

@section('content')
    <nav aria-label="breadcrumb" style="margin-bottom:16px;">
        <ol class="breadcrumb" style="font-size:.75rem;margin:0;">
            <li class="breadcrumb-item"><a href="{{ route('admin.inventories.index') }}">Inventories</a></li>
            <li class="breadcrumb-item active">{{ $inventory->code }}</li>
        </ol>
    </nav>

    <div class="lv-page-header">
        <div>
            <h1>{{ $inventory->name }}</h1>
            <p><code>{{ $inventory->code }}</code> · {{ $inventory->category?->name ?? '—' }}</p>
        </div>
        <div style="display:flex;gap:8px;">
            <a href="{{ route('admin.inventories.edit', $inventory) }}" class="btn btn-ghost btn-sm">
                <i class="bi bi-pencil me-1"></i>Edit
            </a>
            <form method="POST" action="{{ route('admin.inventories.destroy', $inventory) }}"
                  data-confirm="Delete '{{ $inventory->name }}'? This cannot be undone."
                  data-confirm-title="Delete inventory"
                  data-confirm-yes="Yes, delete"
                  data-confirm-tone="danger">
                @csrf @method('DELETE')
                <button type="submit" class="btn btn-sm"
                        style="background:#fef2f2;border:1px solid #fecaca;color:#dc2626;">
                    <i class="bi bi-trash me-1"></i>Delete
                </button>
            </form>
        </div>
    </div>

    <div class="row g-4">
        <div class="col-12 col-lg-8">
            <div class="lv-card">
                <div class="lv-card-header">
                    <span class="lv-card-title"><i class="bi bi-info-circle me-2 text-primary"></i>Inventory details</span>
                    @if ($inventory->status === 'available')
                        <span class="lv-pill lv-pill-available">Available</span>
                    @else
                        <span class="lv-pill lv-pill-out">Out of stock</span>
                    @endif
                </div>
                <div style="padding:20px;">
                    <div class="row g-4">
                        <div class="col-12 col-sm-5">
                            @if ($inventory->image_url)
                                <img src="{{ $inventory->image_url }}"
                                     alt="{{ $inventory->name }}"
                                     style="width:100%;border-radius:16px;border:1px solid #e8eaf0;object-fit:cover;max-height:280px;">
                            @else
                                <div style="width:100%;height:220px;background:#f8f9ff;border-radius:16px;border:1px solid #e8eaf0;display:flex;align-items:center;justify-content:center;">
                                    <i class="bi bi-image" style="font-size:2.5rem;color:#d1d5db;"></i>
                                </div>
                            @endif
                        </div>
                        <div class="col-12 col-sm-7">
                            <div style="margin-bottom:16px;">
                                <div style="font-size:.70rem;font-weight:700;text-transform:uppercase;color:#9ca3af;margin-bottom:4px;">Stock</div>
                                <div style="font-size:2rem;font-weight:800;color:#111827;letter-spacing:-.03em;">{{ $inventory->stock }}</div>
                            </div>
                            <div style="margin-bottom:14px;">
                                <div style="font-size:.70rem;font-weight:700;text-transform:uppercase;color:#9ca3af;margin-bottom:4px;">Description</div>
                                <div style="font-size:.85rem;color:#374151;line-height:1.55;">{{ $inventory->description ?: 'No description provided.' }}</div>
                            </div>
                            <hr style="border-color:#f0f2f8;">
                            <div class="row g-2">
                                <div class="col-6">
                                    <div style="font-size:.68rem;color:#9ca3af;text-transform:uppercase;letter-spacing:.06em;margin-bottom:2px;">Category</div>
                                    <div style="font-size:.82rem;font-weight:600;color:#374151;">{{ $inventory->category?->name ?? '—' }}</div>
                                </div>
                                <div class="col-6">
                                    <div style="font-size:.68rem;color:#9ca3af;text-transform:uppercase;letter-spacing:.06em;margin-bottom:2px;">Created</div>
                                    <div style="font-size:.78rem;color:#374151;">{{ $inventory->created_at?->format('d M Y') }}</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-12 col-lg-4">
            <div class="lv-card" style="text-align:center;">
                <div class="lv-card-header">
                    <span class="lv-card-title"><i class="bi bi-qr-code-scan me-2 text-primary"></i>QR Code</span>
                </div>
                <div style="padding:20px;">
                    @if ($inventory->qr_url)
                        <img src="{{ $inventory->qr_url }}"
                             alt="QR for {{ $inventory->code }}"
                             style="width:180px;height:180px;border-radius:12px;border:1px solid #e8eaf0;object-fit:contain;margin-bottom:14px;">
                        <div>
                            <a href="{{ $inventory->qr_url }}"
                               download="{{ $inventory->code }}.png"
                               class="btn btn-ghost btn-sm" style="width:100%;">
                                <i class="bi bi-download me-1"></i>Download QR
                            </a>
                        </div>
                    @else
                        <div style="width:180px;height:180px;background:#f8f9ff;border-radius:12px;border:1px solid #e8eaf0;display:flex;align-items:center;justify-content:center;margin:0 auto 14px;">
                            <i class="bi bi-qr-code" style="font-size:2.5rem;color:#d1d5db;"></i>
                        </div>
                        <p style="font-size:.78rem;color:#9ca3af;margin:0;">QR not yet generated.</p>
                    @endif
                </div>
            </div>
        </div>
    </div>
@endsection
