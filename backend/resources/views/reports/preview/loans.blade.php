@extends('reports.preview.layout')

@section('title', 'Loan Report')
@section('toolbar-meta',
    $startDate->toDateString() . ' → ' . $endDate->toDateString() .
    ' · generated ' . $generatedAt->toDayDateTimeString() . ' UTC')
@section('download-url',
    route('admin.reports.loans', [
        'start_date' => $startDate->toDateString(),
        'end_date'   => $endDate->toDateString(),
    ]))

@section('content')
    @php
        $pillClasses = [
            'pending'  => 'pill-pending',
            'approved' => 'pill-approved',
            'rejected' => 'pill-rejected',
            'borrowed' => 'pill-borrowed',
            'returned' => 'pill-returned',
        ];
    @endphp

    <div class="report-header">
        <h2>Loan Report</h2>
        <p class="lead">
            Loan transactions submitted between {{ $startDate->toDateString() }}
            and {{ $endDate->toDateString() }} (inclusive).
        </p>
    </div>

    <div class="meta-grid">
        <span class="label">Generated</span>
        <span>{{ $generatedAt->toDayDateTimeString() }} UTC</span>
        <span class="label">Total loans</span>
        <span>{{ number_format($totalLoans) }}</span>

        <span class="label">Range</span>
        <span>{{ $startDate->toDateString() }} → {{ $endDate->toDateString() }}</span>
        <span></span><span></span>
    </div>

    <table class="report-table">
        <thead>
            <tr>
                <th style="width: 4%;">#</th>
                <th style="width: 16%;">Student</th>
                <th style="width: 16%;">Inventory</th>
                <th style="width: 9%;">Borrow</th>
                <th style="width: 9%;">Return</th>
                <th style="width: 9%;">Status</th>
                <th style="width: 11%;">Picked up</th>
                <th style="width: 11%;">Returned</th>
                <th>Notes</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($loans as $loan)
                <tr>
                    <td class="muted">{{ $loan->id }}</td>
                    <td>
                        <strong>{{ $loan->user?->name ?? '—' }}</strong><br>
                        <span class="muted">{{ $loan->user?->nim ?? '' }}</span>
                    </td>
                    <td>
                        {{ $loan->inventory?->name ?? '—' }}<br>
                        <span class="muted code">{{ $loan->inventory?->code ?? '' }}</span>
                    </td>
                    <td>{{ $loan->borrow_date?->toDateString() ?? '—' }}</td>
                    <td>{{ $loan->return_date?->toDateString() ?? '—' }}</td>
                    <td>
                        <span class="pill {{ $pillClasses[$loan->status] ?? 'pill-rejected' }}">
                            {{ $loan->status }}
                        </span>
                    </td>
                    <td class="muted">{{ $loan->picked_up_at?->toDateTimeString() ?? '—' }}</td>
                    <td class="muted">{{ $loan->returned_at?->toDateTimeString() ?? '—' }}</td>
                    <td class="muted">
                        @if ($loan->status === 'rejected' && $loan->reject_reason)
                            <em>Rejected:</em> {{ $loan->reject_reason }}
                        @else
                            {{ $loan->notes ?: '—' }}
                        @endif
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="9" class="empty-state">
                        No loans were submitted in this date range.
                    </td>
                </tr>
            @endforelse
        </tbody>
    </table>
@endsection
