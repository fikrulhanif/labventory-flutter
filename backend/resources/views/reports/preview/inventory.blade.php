@extends('reports.preview.layout')

@section('title', 'Inventory Report')
@section('toolbar-meta', 'Generated ' . $generatedAt->toDayDateTimeString() . ' UTC')
@section('download-url', route('admin.reports.inventory'))

@section('content')
    <div class="report-header">
        <h2>Inventory Report</h2>
        <p class="lead">Snapshot of every inventory item registered with Labventory.</p>
    </div>

    <div class="meta-grid">
        <span class="label">Generated</span>
        <span>{{ $generatedAt->toDayDateTimeString() }} UTC</span>
        <span class="label">Items</span>
        <span>{{ number_format($totalItems) }}</span>

        <span class="label">Total stock</span>
        <span>{{ number_format($totalStock) }}</span>
        <span></span><span></span>
    </div>

    <table class="report-table">
        <thead>
            <tr>
                <th style="width: 14%;">Code</th>
                <th>Name</th>
                <th style="width: 18%;">Category</th>
                <th class="num" style="width: 9%;">Stock</th>
                <th style="width: 14%;">Status</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($inventories as $item)
                <tr>
                    <td class="code"><strong>{{ $item->code }}</strong></td>
                    <td>{{ $item->name }}</td>
                    <td>{{ $item->category?->name ?? '—' }}</td>
                    <td class="num">{{ number_format($item->stock) }}</td>
                    <td>
                        @if ($item->status === 'available')
                            <span class="pill pill-available">available</span>
                        @else
                            <span class="pill pill-out">out of stock</span>
                        @endif
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="5" class="empty-state">No inventory records.</td>
                </tr>
            @endforelse
        </tbody>
    </table>
@endsection
