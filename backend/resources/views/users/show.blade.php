@extends('layouts.admin')

@section('title', $user->name)

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
    <nav aria-label="breadcrumb" class="mb-3">
        <ol class="breadcrumb small mb-0">
            <li class="breadcrumb-item"><a href="{{ route('admin.users.index') }}">Students</a></li>
            <li class="breadcrumb-item active" aria-current="page">{{ $user->name }}</li>
        </ol>
    </nav>

    <div class="d-flex flex-wrap align-items-center justify-content-between mb-4 gap-2">
        <div>
            <h1 class="h4 mb-1 fw-semibold">{{ $user->name }}</h1>
            <p class="text-muted small mb-0">
                Student profile and complete loan history.
            </p>
        </div>
        <div class="d-flex gap-2">
            <a href="{{ route('admin.users.edit', $user) }}" class="btn btn-light">
                <i class="bi bi-pencil me-1"></i> Edit
            </a>
        </div>
    </div>

    <div class="row g-4 mb-4">
        {{-- Profile card --}}
        <div class="col-12 col-lg-4">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body p-4">
                    <h2 class="h6 fw-semibold mb-3">Profile</h2>
                    <dl class="row small mb-0">
                        <dt class="col-sm-4 text-muted">Name</dt>
                        <dd class="col-sm-8">{{ $user->name }}</dd>

                        <dt class="col-sm-4 text-muted">NIM</dt>
                        <dd class="col-sm-8"><code>{{ $user->nim ?? '—' }}</code></dd>

                        <dt class="col-sm-4 text-muted">Email</dt>
                        <dd class="col-sm-8">{{ $user->email }}</dd>

                        <dt class="col-sm-4 text-muted">Status</dt>
                        <dd class="col-sm-8">
                            @if ($user->status === 'active')
                                <span class="badge text-bg-success">Active</span>
                            @else
                                <span class="badge text-bg-secondary">Inactive</span>
                            @endif
                        </dd>

                        <dt class="col-sm-4 text-muted">Joined</dt>
                        <dd class="col-sm-8">
                            {{ $user->created_at?->toDayDateTimeString() }}
                        </dd>
                    </dl>
                </div>
            </div>
        </div>

        {{-- Stats grid --}}
        <div class="col-12 col-lg-8">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body p-4">
                    <h2 class="h6 fw-semibold mb-3">Loan statistics</h2>

                    <div class="row g-3 row-cols-2 row-cols-md-3">
                        <div class="col">
                            <div class="border rounded p-3 h-100">
                                <div class="text-muted small text-uppercase">Total</div>
                                <div class="h4 fw-semibold mb-0">{{ number_format($stats['total']) }}</div>
                            </div>
                        </div>
                        <div class="col">
                            <div class="border rounded p-3 h-100" style="border-left: 3px solid var(--bs-warning) !important;">
                                <div class="text-muted small text-uppercase">Pending</div>
                                <div class="h4 fw-semibold mb-0">{{ number_format($stats['pending']) }}</div>
                            </div>
                        </div>
                        <div class="col">
                            <div class="border rounded p-3 h-100" style="border-left: 3px solid var(--bs-info) !important;">
                                <div class="text-muted small text-uppercase">Approved</div>
                                <div class="h4 fw-semibold mb-0">{{ number_format($stats['approved']) }}</div>
                            </div>
                        </div>
                        <div class="col">
                            <div class="border rounded p-3 h-100" style="border-left: 3px solid var(--bs-primary) !important;">
                                <div class="text-muted small text-uppercase">Borrowed</div>
                                <div class="h4 fw-semibold mb-0">{{ number_format($stats['borrowed']) }}</div>
                            </div>
                        </div>
                        <div class="col">
                            <div class="border rounded p-3 h-100" style="border-left: 3px solid var(--bs-success) !important;">
                                <div class="text-muted small text-uppercase">Returned</div>
                                <div class="h4 fw-semibold mb-0">{{ number_format($stats['returned']) }}</div>
                            </div>
                        </div>
                        <div class="col">
                            <div class="border rounded p-3 h-100" style="border-left: 3px solid var(--bs-secondary) !important;">
                                <div class="text-muted small text-uppercase">Rejected</div>
                                <div class="h4 fw-semibold mb-0">{{ number_format($stats['rejected']) }}</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    {{-- Loan history --}}
    <div class="card border-0 shadow-sm">
        <div class="card-header bg-white py-3 border-0 d-flex flex-wrap align-items-center justify-content-between gap-2">
            <div>
                <h2 class="h6 fw-semibold mb-1">Loan history</h2>
                <p class="text-muted small mb-0">
                    Every loan submitted by this student, newest first.
                </p>
            </div>
            <form method="GET" class="d-flex align-items-center gap-2">
                <label for="status" class="form-label small fw-medium mb-0 text-muted">Filter</label>
                <select id="status" name="status" class="form-select form-select-sm" onchange="this.form.submit()">
                    <option value="">All statuses</option>
                    @foreach ($statusOptions as $value => $label)
                        <option value="{{ $value }}" @selected($status === $value)>{{ $label }}</option>
                    @endforeach
                </select>
                @if ($status !== '')
                    <a href="{{ route('admin.users.show', $user) }}" class="btn btn-sm btn-link text-muted">Clear</a>
                @endif
            </form>
        </div>

        <div class="card-body p-0">
            @if ($loans->isEmpty())
                <div class="text-center text-muted py-5">
                    <i class="bi bi-clipboard display-6 d-block mb-2"></i>
                    @if ($status !== '')
                        No <code>{{ $status }}</code> loans on file for this student.
                    @else
                        This student has not submitted any loan requests yet.
                    @endif
                </div>
            @else
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="ps-4">Inventory</th>
                                <th>Period</th>
                                <th>Status</th>
                                <th>Picked up</th>
                                <th>Returned</th>
                                <th>Submitted</th>
                                <th class="pe-4 text-end">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($loans as $loan)
                                <tr>
                                    <td class="ps-4">
                                        <div class="fw-medium">{{ $loan->inventory?->name ?? '—' }}</div>
                                        <div class="text-muted small">
                                            <code>{{ $loan->inventory?->code ?? '' }}</code>
                                        </div>
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
                                        {{ $loan->picked_up_at?->toDayDateTimeString() ?? '—' }}
                                    </td>
                                    <td class="text-muted small">
                                        {{ $loan->returned_at?->toDayDateTimeString() ?? '—' }}
                                    </td>
                                    <td class="text-muted small">
                                        {{ $loan->created_at?->diffForHumans() }}
                                    </td>
                                    <td class="pe-4 text-end">
                                        <a href="{{ route('admin.loans.show', $loan) }}"
                                           class="btn btn-sm btn-light">
                                            <i class="bi bi-eye me-1"></i> View
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
