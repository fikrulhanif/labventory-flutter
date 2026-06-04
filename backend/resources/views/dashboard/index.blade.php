@extends('layouts.admin')

@section('title', 'Dashboard')

@php
    $statCards = [
        ['Inventories',       $stats['total_inventories'], 'bi-boxes',              'lv-stat-1'],
        ['Students',          $stats['total_students'],    'bi-people-fill',        'lv-stat-2'],
        ['Total loans',       $stats['total_loans'],       'bi-clipboard2-check',   'lv-stat-3'],
        ['Available items',   $stats['available_count'],   'bi-check-circle-fill',  'lv-stat-4'],
        ['Currently borrowed',$stats['borrowed_count'],    'bi-arrow-left-right',   'lv-stat-5'],
    ];
@endphp

@section('content')
    <div class="lv-page-header">
        <div>
            <h1>Dashboard</h1>
            <p>Lab inventory at a glance · {{ now()->format('l, d F Y') }}</p>
        </div>
        <a href="{{ route('admin.loans.index') }}" class="btn btn-primary btn-sm">
            <i class="bi bi-clipboard2-list me-1"></i> View all loans
        </a>
    </div>

    {{-- Stat cards --}}
    <div class="row g-3 mb-4">
        @foreach ($statCards as [$label, $value, $icon, $cls])
            <div class="col-12 col-sm-6 col-lg">
                <div class="lv-stat {{ $cls }}">
                    <div class="lv-stat-icon">
                        <i class="bi {{ $icon }}"></i>
                    </div>
                    <div>
                        <div class="lv-stat-label">{{ $label }}</div>
                        <div class="lv-stat-value">{{ number_format($value) }}</div>
                    </div>
                </div>
            </div>
        @endforeach
    </div>

    {{-- Recent loans table --}}
    <div class="lv-card">
        <div class="lv-card-header">
            <span class="lv-card-title"><i class="bi bi-clock-history me-2 text-primary"></i>Recent loan requests</span>
            <a href="{{ route('admin.loans.index') }}" class="btn btn-ghost btn-sm">
                See all <i class="bi bi-arrow-right ms-1"></i>
            </a>
        </div>

        @if ($recentLoans->isEmpty())
            <div class="lv-empty">
                <i class="bi bi-inbox"></i>
                <p>No loan requests yet.</p>
            </div>
        @else
            <div style="overflow-x:auto;">
                <table class="lv-table">
                    <thead>
                        <tr>
                            <th>Student</th>
                            <th>NIM</th>
                            <th>Inventory</th>
                            <th>Status</th>
                            <th style="text-align:right;">Submitted</th>
                            <th style="text-align:right;">Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($recentLoans as $loan)
                            <tr>
                                <td style="font-weight:600;">{{ $loan->user?->name ?? '—' }}</td>
                                <td><code>{{ $loan->user?->nim ?? '—' }}</code></td>
                                <td>
                                    <div style="font-weight:600;">{{ $loan->inventory?->name ?? '—' }}</div>
                                    <div style="font-size:.72rem;color:#9ca3af;">{{ $loan->inventory?->code ?? '' }}</div>
                                </td>
                                <td>
                                    <span class="lv-pill lv-pill-{{ $loan->status }}">
                                        {{ ucfirst($loan->status) }}
                                    </span>
                                </td>
                                <td style="text-align:right;color:#9ca3af;font-size:.78rem;">
                                    {{ $loan->created_at?->diffForHumans() }}
                                </td>
                                <td style="text-align:right;">
                                    <a href="{{ route('admin.loans.show', $loan) }}"
                                       class="btn btn-ghost btn-sm">
                                        <i class="bi bi-eye"></i>
                                    </a>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif
    </div>
@endsection
