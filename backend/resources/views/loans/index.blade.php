@extends('layouts.admin')

@section('title', 'Loans')

@php
    $statusColors = [
        'pending'  => 'warning',
        'approved' => 'info',
        'borrowed' => 'primary',
        'returned' => 'success',
        'rejected' => 'secondary',
    ];

    $statusOptions = [
        'pending'  => 'Pending',
        'approved' => 'Approved',
        'borrowed' => 'Borrowed',
        'returned' => 'Returned',
        'rejected' => 'Rejected',
    ];
@endphp

@section('content')
    <div class="d-flex flex-wrap align-items-center justify-content-between mb-4 gap-3">
        <div>
            <h1 class="h4 mb-1 fw-semibold">Loans</h1>
            <p class="text-muted small mb-0">Borrow requests from students.</p>
        </div>
    </div>

    <div class="card border-0 shadow-sm">
        <div class="card-header bg-white py-3 border-0">
            <form method="GET" class="row g-2 align-items-end">
                <div class="col-12 col-md-4">
                    <label for="status" class="form-label small fw-medium mb-1">Status</label>
                    <select id="status" name="status" class="form-select">
                        <option value="">All statuses</option>
                        @foreach ($statusOptions as $value => $label)
                            <option value="{{ $value }}" @selected($selectedStatus === $value)>{{ $label }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-12 col-md-3 d-flex gap-2">
                    <button class="btn btn-light w-100" type="submit">Apply</button>
                    @if ($selectedStatus)
                        <a href="{{ route('admin.loans.index') }}" class="btn btn-link text-muted">Reset</a>
                    @endif
                </div>
            </form>
        </div>

        <div class="card-body p-0">
            @if ($loans->isEmpty())
                <div class="text-center text-muted py-5">
                    <i class="bi bi-clipboard display-6 d-block mb-2"></i>
                    No loan requests match these filters.
                </div>
            @else
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="ps-4">Student</th>
                                <th>Inventory</th>
                                <th>Period</th>
                                <th>Status</th>
                                <th>Submitted</th>
                                <th class="pe-4 text-end">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($loans as $loan)
                                <tr>
                                    <td class="ps-4">
                                        <div class="fw-medium">{{ $loan->user?->name ?? '-' }}</div>
                                        <div class="text-muted small">{{ $loan->user?->nim ?? '' }}</div>
                                    </td>
                                    <td>
                                        <div class="fw-medium">{{ $loan->inventory?->name ?? '-' }}</div>
                                        <div class="text-muted small"><code>{{ $loan->inventory?->code ?? '' }}</code></div>
                                    </td>
                                    <td class="text-muted small">
                                        {{ $loan->borrow_date?->toDateString() }}
                                        &rarr;
                                        {{ $loan->return_date?->toDateString() }}
                                    </td>
                                    <td>
                                        <span class="badge text-bg-{{ $statusColors[$loan->status] ?? 'secondary' }} text-uppercase">
                                            {{ $loan->status }}
                                        </span>
                                    </td>
                                    <td class="text-muted small">
                                        {{ $loan->created_at?->diffForHumans() }}
                                    </td>
                                    <td class="pe-4 text-end">
                                        <a href="{{ route('admin.loans.show', $loan) }}"
                                           class="btn btn-sm btn-light">
                                            <i class="bi bi-eye me-1"></i> Review
                                        </a>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endif
        </div>

        @if ($loans->hasPages())
            <div class="card-footer bg-white border-0">
                {{ $loans->links() }}
            </div>
        @endif
    </div>
@endsection
