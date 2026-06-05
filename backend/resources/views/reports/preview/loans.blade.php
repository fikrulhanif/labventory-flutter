@extends('reports.preview.layout')

@section('title', 'Loan Report')
@section('toolbar-meta',
    $startDate->toDateString() . ' → ' . $endDate->toDateString() .
    ' · generated ' . $generatedAt->toDayDateTimeString() . ' UTC')
@section('report-subtitle', 'Loan transactions within the selected date range.')
@section('download-url',
    route('admin.reports.loans', [
        'start_date' => $startDate->toDateString(),
        'end_date'   => $endDate->toDateString(),
    ]))

@section('content')
    @php
        $byStatus = $loans->groupBy('status');
        $countFor = fn($s) => $byStatus->get($s)?->count() ?? 0;
        $statChips = [
            ['Total', $totalLoans, '#6366f1', 'bi-clipboard-data'],
            ['Pending',  $countFor('pending'),  '#b45309', 'bi-hourglass'],
            ['Approved', $countFor('approved'), '#0e7490', 'bi-thumb-up'],
            ['Borrowed', $countFor('borrowed'), '#6d28d9', 'bi-arrow-left-right'],
            ['Returned', $countFor('returned'), '#065f46', 'bi-check-circle'],
            ['Rejected', $countFor('rejected'), '#374151', 'bi-x-circle'],
        ];
    @endphp

    {{-- Meta chips --}}
    <div class="report-meta">
        @foreach ($statChips as [$label, $value, $color, $icon])
            @php
                $bgMap = [
                    '#6366f1' => 'background:#6366f1',
                    '#b45309' => 'background:#b45309',
                    '#0e7490' => 'background:#0e7490',
                    '#6d28d9' => 'background:#6d28d9',
                    '#065f46' => 'background:#065f46',
                    '#374151' => 'background:#374151',
                ];
                $bgStyle = $bgMap[$color] ?? ('background:' . $color);
            @endphp
            <div class="meta-chip">
                <div class="meta-chip-icon" style="{{ $bgStyle }};"><i class="bi {{ $icon }}"></i></div>
                <div>
                    <div class="meta-chip-label">{{ $label }}</div>
                    <div class="meta-chip-value">{{ number_format($value) }}</div>
                </div>
            </div>
        @endforeach
    </div>

    <div class="section-title"><i class="bi bi-calendar-range" style="color:#6366f1;"></i>Period: {{ $startDate->toDateString() }} — {{ $endDate->toDateString() }}</div>

    <table class="report-table">
        <thead>
            <tr>
                <th style="width:5%;">#</th>
                <th style="width:17%;">Student</th>
                <th style="width:20%;">Inventory</th>
                <th style="width:10%;">Borrow</th>
                <th style="width:10%;">Return</th>
                <th style="width:10%;">Status</th>
                <th style="width:13%;">Picked up</th>
                <th>Notes</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($loans as $loan)
                <tr>
                    <td class="muted">{{ $loan->id }}</td>
                    <td>
                        <strong>{{ $loan->user?->name ?? '—' }}</strong><br>
                        <span class="muted"><code>{{ $loan->user?->nim ?? '' }}</code></span>
                    </td>
                    <td>
                        {{ $loan->inventory?->name ?? '—' }}<br>
                        <code>{{ $loan->inventory?->code ?? '' }}</code>
                    </td>
                    <td class="muted">{{ $loan->borrow_date?->toDateString() ?? '—' }}</td>
                    <td class="muted">{{ $loan->return_date?->toDateString() ?? '—' }}</td>
                    <td>
                        <span class="pill pill-{{ $loan->status }}">{{ ucfirst($loan->status) }}</span>
                    </td>
                    <td class="muted">
                        {{ $loan->picked_up_at?->format('d M, H:i') ?? '—' }}
                    </td>
                    <td class="muted">
                        @if ($loan->status === 'rejected' && $loan->reject_reason)
                            <span style="color:#b45309;font-style:italic;">{{ $loan->reject_reason }}</span>
                        @else
                            {{ $loan->notes ?: '—' }}
                        @endif
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="8">
                        <div class="empty-state">
                            <i class="bi bi-clipboard"></i>
                            <p>No loans were submitted in this date range.</p>
                        </div>
                    </td>
                </tr>
            @endforelse
        </tbody>
    </table>
@endsection
