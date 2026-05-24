@extends('layouts.admin')

@section('title', 'Dashboard')

@php
    $statusColors = [
        'pending'  => 'warning',
        'approved' => 'info',
        'borrowed' => 'primary',
        'returned' => 'success',
        'rejected' => 'secondary',
    ];
@endphp

@section('content')
    <div class="d-flex align-items-center justify-content-between mb-4">
        <div>
            <h1 class="h4 mb-1 fw-semibold">Dashboard</h1>
            <p class="text-muted small mb-0">Lab inventory at a glance.</p>
        </div>
    </div>

    <div class="row g-3 mb-4">
        @php
            $cards = [
                ['Inventories', $stats['total_inventories'], 'bi-boxes', 'primary'],
                ['Students', $stats['total_students'], 'bi-people', 'info'],
                ['Total loans', $stats['total_loans'], 'bi-clipboard-check', 'secondary'],
                ['Available items', $stats['available_count'], 'bi-check-circle', 'success'],
                ['Currently borrowed', $stats['borrowed_count'], 'bi-arrow-repeat', 'warning'],
            ];
        @endphp

        @foreach ($cards as [$label, $value, $icon, $tone])
            <div class="col-12 col-sm-6 col-lg">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-body p-3">
                        <div class="d-flex align-items-center gap-3">
                            <div class="bg-{{ $tone }} bg-opacity-10 text-{{ $tone }} rounded-3 d-flex align-items-center justify-content-center"
                                 style="width:44px;height:44px;">
                                <i class="bi {{ $icon }} fs-5"></i>
                            </div>
                            <div>
                                <div class="text-muted text-uppercase small">{{ $label }}</div>
                                <div class="h4 fw-semibold mb-0">{{ $value }}</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        @endforeach
    </div>

    <div class="card border-0 shadow-sm">
        <div class="card-header bg-white py-3 border-0 d-flex align-items-center justify-content-between">
            <h2 class="h6 mb-0 fw-semibold">Recent loans</h2>
            <span class="text-muted small">Last 5 requests</span>
        </div>
        <div class="card-body p-0">
            @if ($recentLoans->isEmpty())
                <div class="text-center text-muted py-5">
                    <i class="bi bi-inbox display-6 d-block mb-2"></i>
                    No loan requests yet.
                </div>
            @else
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="ps-4">Student</th>
                                <th>NIM</th>
                                <th>Inventory</th>
                                <th>Status</th>
                                <th class="pe-4 text-end">Submitted</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($recentLoans as $loan)
                                <tr>
                                    <td class="ps-4">{{ $loan->user?->name ?? '-' }}</td>
                                    <td><span class="text-muted small">{{ $loan->user?->nim ?? '-' }}</span></td>
                                    <td>
                                        <div class="fw-medium">{{ $loan->inventory?->name ?? '-' }}</div>
                                        <div class="text-muted small">{{ $loan->inventory?->code ?? '' }}</div>
                                    </td>
                                    <td>
                                        <span class="badge text-bg-{{ $statusColors[$loan->status] ?? 'secondary' }} text-uppercase">
                                            {{ $loan->status }}
                                        </span>
                                    </td>
                                    <td class="pe-4 text-end text-muted small">
                                        {{ $loan->created_at?->diffForHumans() }}
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endif
        </div>
    </div>
@endsection
