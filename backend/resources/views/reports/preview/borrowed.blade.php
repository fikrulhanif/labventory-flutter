@extends('reports.preview.layout')

@section('title', 'Currently Borrowed Inventory')
@section('toolbar-meta', 'Generated ' . $generatedAt->toDayDateTimeString() . ' UTC')
@section('download-url', route('admin.reports.borrowed'))

@section('content')
    <div class="report-header">
        <h2>Currently Borrowed Inventory</h2>
        <p class="lead">Snapshot of items currently checked out of the lab.</p>
    </div>

    <div class="meta-grid">
        <span class="label">Generated</span>
        <span>{{ $generatedAt->toDayDateTimeString() }} UTC</span>
        <span class="label">Items out</span>
        <span>{{ number_format($totalItems) }}</span>

        <span class="label">Borrowed loans</span>
        <span>{{ number_format($totalBorrowed) }}</span>
        <span></span><span></span>
    </div>

    <table class="report-table">
        <thead>
            <tr>
                <th style="width: 11%;">Code</th>
                <th style="width: 18%;">Name</th>
                <th style="width: 12%;">Category</th>
                <th class="num" style="width: 7%;">Stock</th>
                <th class="num" style="width: 8%;">Borrowed</th>
                <th>Borrowers</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($rows as $row)
                <tr>
                    <td class="code"><strong>{{ $row['inventory']?->code }}</strong></td>
                    <td>{{ $row['inventory']?->name }}</td>
                    <td>{{ $row['inventory']?->category?->name ?? '—' }}</td>
                    <td class="num">{{ number_format($row['available_count']) }}</td>
                    <td class="num"><strong>{{ number_format($row['borrowed_count']) }}</strong></td>
                    <td>
                        <ul style="margin: 0; padding: 0; list-style: none;">
                            @foreach ($row['loans'] as $loan)
                                <li style="padding: 0.15rem 0; border-top: 1px dashed #e5e7eb; font-size: 0.825rem;">
                                    <strong>{{ $loan->user?->name ?? '—' }}</strong>
                                    <span class="muted">({{ $loan->user?->nim ?? '' }})</span>
                                    &nbsp;·&nbsp;
                                    {{ $loan->borrow_date?->toDateString() ?? '—' }}
                                    &rarr;
                                    {{ $loan->return_date?->toDateString() ?? '—' }}
                                </li>
                            @endforeach
                        </ul>
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="6" class="empty-state">
                        No inventory is currently borrowed.
                    </td>
                </tr>
            @endforelse
        </tbody>
    </table>
@endsection
