@extends('reports.preview.layout')

@section('title', 'Most Borrowed Inventory')
@section('toolbar-meta',
    $startDate->toDateString() . ' → ' . $endDate->toDateString() .
    ' · top ' . $limit .
    ' · generated ' . $generatedAt->toDayDateTimeString() . ' UTC')
@section('download-url',
    route('admin.reports.popular', [
        'start_date' => $startDate->toDateString(),
        'end_date'   => $endDate->toDateString(),
    ]))

@section('content')
    <div class="report-header">
        <h2>Most Borrowed Inventory</h2>
        <p class="lead">
            Top {{ $limit }} most-requested inventory between {{ $startDate->toDateString() }}
            and {{ $endDate->toDateString() }} (inclusive). Counts every loan submitted in
            the period regardless of final status.
        </p>
    </div>

    <div class="meta-grid">
        <span class="label">Generated</span>
        <span>{{ $generatedAt->toDayDateTimeString() }} UTC</span>
        <span class="label">Items ranked</span>
        <span>{{ number_format($rows->count()) }}</span>

        <span class="label">Range</span>
        <span>{{ $startDate->toDateString() }} → {{ $endDate->toDateString() }}</span>
        <span class="label">Loan count</span>
        <span>{{ number_format($totalLoans) }}</span>
    </div>

    <table class="report-table">
        <thead>
            <tr>
                <th class="num" style="width: 8%;">#</th>
                <th style="width: 16%;">Code</th>
                <th>Name</th>
                <th style="width: 22%;">Category</th>
                <th class="num" style="width: 14%;">Loan count</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($rows as $row)
                <tr>
                    <td class="num" style="font-weight: 700; color: #4f46e5;">{{ $row['rank'] }}</td>
                    <td class="code">{{ $row['inventory']?->code ?? '—' }}</td>
                    <td>{{ $row['inventory']?->name ?? '—' }}</td>
                    <td>{{ $row['inventory']?->category?->name ?? '—' }}</td>
                    <td class="num"><strong>{{ number_format($row['loan_count']) }}</strong></td>
                </tr>
            @empty
                <tr>
                    <td colspan="5" class="empty-state">
                        No loans were submitted in this date range.
                    </td>
                </tr>
            @endforelse
        </tbody>
    </table>
@endsection
