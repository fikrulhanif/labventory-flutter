@extends('reports.preview.layout')

@section('title', 'Inventory Report')
@section('toolbar-meta', 'Generated ' . $generatedAt->toDayDateTimeString() . ' UTC')
@section('report-subtitle', 'Snapshot of all registered inventory items.')
@section('download-url', route('admin.reports.inventory'))

@section('content')
    {{-- Meta chips --}}
    <div class="report-meta">
        <div class="meta-chip">
            <div class="meta-chip-icon" style="background:#6366f1;"><i class="bi bi-boxes"></i></div>
            <div>
                <div class="meta-chip-label">Total items</div>
                <div class="meta-chip-value">{{ number_format($totalItems) }}</div>
            </div>
        </div>
        <div class="meta-chip">
            <div class="meta-chip-icon" style="background:#10b981;"><i class="bi bi-stack"></i></div>
            <div>
                <div class="meta-chip-label">Total stock</div>
                <div class="meta-chip-value">{{ number_format($totalStock) }}</div>
            </div>
        </div>
        <div class="meta-chip">
            <div class="meta-chip-icon" style="background:#0ea5e9;"><i class="bi bi-calendar-date"></i></div>
            <div>
                <div class="meta-chip-label">Generated</div>
                <div class="meta-chip-value" style="font-size:.75rem;font-weight:700;">{{ $generatedAt->format('d M Y') }}</div>
            </div>
        </div>
    </div>

    <div class="section-title"><i class="bi bi-list-ul" style="color:#6366f1;"></i>Inventory catalog</div>

    <table class="report-table">
        <thead>
            <tr>
                <th style="width:16%;">Code</th>
                <th>Item name</th>
                <th style="width:20%;">Category</th>
                <th class="num" style="width:10%;">Stock</th>
                <th style="width:16%;">Status</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($inventories as $item)
                <tr>
                    <td><code>{{ $item->code }}</code></td>
                    <td><strong>{{ $item->name }}</strong></td>
                    <td>{{ $item->category?->name ?? '—' }}</td>
                    <td class="num">{{ number_format($item->stock) }}</td>
                    <td>
                        @if ($item->status === 'available')
                            <span class="pill pill-available">Available</span>
                        @else
                            <span class="pill pill-out">Out of stock</span>
                        @endif
                    </td>
                </tr>
            @empty
                <tr><td colspan="5" class="empty-state">No inventory records.</td></tr>
            @endforelse
        </tbody>
    </table>
@endsection
