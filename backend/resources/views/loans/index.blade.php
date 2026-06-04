@extends('layouts.admin')

@section('title', 'Loans')

@php
    $statusOptions = ['pending'=>'Pending','approved'=>'Approved','borrowed'=>'Borrowed','returned'=>'Returned','rejected'=>'Rejected'];
@endphp

@section('content')
    <div class="lv-page-header">
        <div>
            <h1>Loan Requests</h1>
            <p>Manage and process student borrow requests.</p>
        </div>
        {{-- Quick stats chips --}}
        <div style="display:flex;gap:8px;flex-wrap:wrap;">
            @foreach ($statusOptions as $val => $label)
                <a href="{{ route('admin.loans.index', ['status' => $val]) }}"
                   class="btn btn-sm {{ $selectedStatus === $val ? 'btn-primary' : 'btn-ghost' }}"
                   style="border-radius:999px;">
                    <span class="lv-pill lv-pill-{{ $val }}" style="background:none;border:none;padding:0;">{{ $label }}</span>
                </a>
            @endforeach
            @if ($selectedStatus)
                <a href="{{ route('admin.loans.index') }}" class="btn btn-sm btn-ghost" style="border-radius:999px;">
                    <i class="bi bi-x"></i> Clear
                </a>
            @endif
        </div>
    </div>

    <div class="lv-card">
        {{-- Filter bar --}}
        <div class="lv-card-header" style="background:#f8f9ff;">
            <form method="GET" class="lv-filters">
                <div class="lv-filter-field">
                    <label class="form-label" for="status">Status</label>
                    <select id="status" name="status" class="form-select form-select-sm">
                        <option value="">All statuses</option>
                        @foreach ($statusOptions as $val => $label)
                            <option value="{{ $val }}" @selected($selectedStatus === $val)>{{ $label }}</option>
                        @endforeach
                    </select>
                </div>
                <div style="display:flex;gap:8px;align-items:flex-end;">
                    <button class="btn btn-apply btn-sm" type="submit">
                        <i class="bi bi-funnel me-1"></i>Filter
                    </button>
                    @if ($selectedStatus)
                        <a href="{{ route('admin.loans.index') }}" class="btn btn-ghost btn-sm">Reset</a>
                    @endif
                </div>
            </form>
        </div>

        @if ($loans->isEmpty())
            <div class="lv-empty">
                <i class="bi bi-clipboard"></i>
                <p>No loan requests match the current filter.</p>
            </div>
        @else
            <div style="overflow-x:auto;">
                <table class="lv-table">
                    <thead>
                        <tr>
                            <th>Student</th>
                            <th>Inventory</th>
                            <th>Period</th>
                            <th>Status</th>
                            <th>Submitted</th>
                            <th style="text-align:right;">Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($loans as $loan)
                            <tr>
                                <td>
                                    <div style="font-weight:600;">{{ $loan->user?->name ?? '—' }}</div>
                                    <div style="font-size:.72rem;color:#9ca3af;"><code>{{ $loan->user?->nim ?? '' }}</code></div>
                                </td>
                                <td>
                                    <div style="font-weight:600;">{{ $loan->inventory?->name ?? '—' }}</div>
                                    <div style="font-size:.72rem;color:#9ca3af;"><code>{{ $loan->inventory?->code ?? '' }}</code></div>
                                </td>
                                <td style="font-size:.78rem;color:#6b7280;white-space:nowrap;">
                                    {{ $loan->borrow_date?->toDateString() }}
                                    <span style="opacity:.5;">→</span>
                                    {{ $loan->return_date?->toDateString() }}
                                </td>
                                <td>
                                    <span class="lv-pill lv-pill-{{ $loan->status }}">{{ ucfirst($loan->status) }}</span>
                                </td>
                                <td style="font-size:.78rem;color:#9ca3af;">
                                    {{ $loan->created_at?->diffForHumans() }}
                                </td>
                                <td style="text-align:right;">
                                    <a href="{{ route('admin.loans.show', $loan) }}"
                                       class="btn btn-primary btn-sm">
                                        <i class="bi bi-eye me-1"></i>Review
                                    </a>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif

        @if ($loans->hasPages())
            <div style="padding:14px 20px;border-top:1px solid #f0f2f8;">
                {{ $loans->links() }}
            </div>
        @endif
    </div>
@endsection
