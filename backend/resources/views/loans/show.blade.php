@extends('layouts.admin')

@section('title', 'Loan #'.$loan->id)

@php
    $statusColors = [
        'pending'  => 'warning',
        'approved' => 'info',
        'borrowed' => 'primary',
        'returned' => 'success',
        'rejected' => 'secondary',
    ];

    $documentExt = strtolower(pathinfo($loan->document, PATHINFO_EXTENSION));
    $isPdf = $documentExt === 'pdf';
@endphp

@section('content')
    <nav aria-label="breadcrumb" class="mb-3">
        <ol class="breadcrumb small mb-0">
            <li class="breadcrumb-item"><a href="{{ route('admin.loans.index') }}">Loans</a></li>
            <li class="breadcrumb-item active" aria-current="page">#{{ $loan->id }}</li>
        </ol>
    </nav>

    <div class="d-flex flex-wrap align-items-center justify-content-between mb-4 gap-2">
        <div>
            <h1 class="h4 mb-1 fw-semibold">Loan #{{ $loan->id }}</h1>
            <span class="badge text-bg-{{ $statusColors[$loan->status] ?? 'secondary' }} text-uppercase">
                {{ $loan->status }}
            </span>
        </div>
        <div class="d-flex flex-wrap gap-2">
            @if ($loan->status === 'pending')
                <form method="POST" action="{{ route('admin.loans.approve', $loan) }}"
                      onsubmit="return confirm('Approve this loan request?');">
                    @csrf
                    <button class="btn btn-info">
                        <i class="bi bi-check-lg me-1"></i> Approve
                    </button>
                </form>
                <button class="btn btn-outline-danger" data-bs-toggle="modal" data-bs-target="#rejectModal">
                    <i class="bi bi-x-lg me-1"></i> Reject
                </button>
            @elseif ($loan->status === 'approved')
                <form method="POST" action="{{ route('admin.loans.pickup', $loan) }}"
                      onsubmit="return confirm('Mark this loan as picked up? Stock will decrement by 1.');">
                    @csrf
                    <button class="btn btn-primary">
                        <i class="bi bi-box-arrow-up-right me-1"></i> Mark as picked up
                    </button>
                </form>
            @elseif ($loan->status === 'borrowed')
                <form method="POST" action="{{ route('admin.loans.return', $loan) }}"
                      onsubmit="return confirm('Mark this item as returned? Stock will increment by 1.');">
                    @csrf
                    <button class="btn btn-success">
                        <i class="bi bi-arrow-counterclockwise me-1"></i> Mark as returned
                    </button>
                </form>
            @endif
        </div>
    </div>

    <div class="row g-4">
        <div class="col-12 col-lg-8">
            <div class="card border-0 shadow-sm mb-4">
                <div class="card-header bg-white py-3 border-0">
                    <h2 class="h6 mb-0 fw-semibold">Request details</h2>
                </div>
                <div class="card-body p-4">
                    <dl class="row mb-0">
                        <dt class="col-sm-4 text-muted small">Student</dt>
                        <dd class="col-sm-8">
                            {{ $loan->user?->name ?? '-' }}
                            <div class="text-muted small">
                                NIM {{ $loan->user?->nim ?? '-' }} · {{ $loan->user?->email ?? '-' }}
                            </div>
                        </dd>

                        <dt class="col-sm-4 text-muted small">Inventory</dt>
                        <dd class="col-sm-8">
                            <a href="{{ route('admin.inventories.show', $loan->inventory) }}">
                                {{ $loan->inventory?->name ?? '-' }}
                            </a>
                            <div class="text-muted small">
                                <code>{{ $loan->inventory?->code ?? '' }}</code>
                                · {{ $loan->inventory?->category?->name ?? '-' }}
                                · stock now: {{ $loan->inventory?->stock ?? 0 }}
                            </div>
                        </dd>

                        <dt class="col-sm-4 text-muted small">Borrow date</dt>
                        <dd class="col-sm-8">{{ $loan->borrow_date?->toDateString() }}</dd>

                        <dt class="col-sm-4 text-muted small">Return date</dt>
                        <dd class="col-sm-8">{{ $loan->return_date?->toDateString() }}</dd>

                        @if ($loan->picked_up_at)
                            <dt class="col-sm-4 text-muted small">Picked up at</dt>
                            <dd class="col-sm-8">{{ $loan->picked_up_at->toDayDateTimeString() }}</dd>
                        @endif

                        @if ($loan->returned_at)
                            <dt class="col-sm-4 text-muted small">Returned at</dt>
                            <dd class="col-sm-8">{{ $loan->returned_at->toDayDateTimeString() }}</dd>
                        @endif

                        <dt class="col-sm-4 text-muted small">Notes</dt>
                        <dd class="col-sm-8">{{ $loan->notes ?: '—' }}</dd>

                        @if ($loan->reject_reason)
                            <dt class="col-sm-4 text-muted small">Rejection reason</dt>
                            <dd class="col-sm-8 text-danger">{{ $loan->reject_reason }}</dd>
                        @endif
                    </dl>
                </div>
            </div>

            <div class="card border-0 shadow-sm">
                <div class="card-header bg-white py-3 border-0">
                    <h2 class="h6 mb-0 fw-semibold">Status history</h2>
                </div>
                <div class="card-body p-0">
                    @if ($loan->statusHistory->isEmpty())
                        <p class="text-muted small p-4 mb-0">No status changes yet.</p>
                    @else
                        <ul class="list-group list-group-flush">
                            @foreach ($loan->statusHistory->sortByDesc('created_at') as $entry)
                                <li class="list-group-item">
                                    <div class="d-flex justify-content-between">
                                        <div>
                                            <span class="badge text-bg-{{ $statusColors[$entry->from_status] ?? 'secondary' }} text-uppercase">{{ $entry->from_status }}</span>
                                            <i class="bi bi-arrow-right mx-1 text-muted"></i>
                                            <span class="badge text-bg-{{ $statusColors[$entry->to_status] ?? 'secondary' }} text-uppercase">{{ $entry->to_status }}</span>
                                        </div>
                                        <span class="text-muted small">{{ $entry->created_at?->diffForHumans() }}</span>
                                    </div>
                                    <div class="text-muted small mt-1">
                                        by {{ $entry->actor?->name ?? 'system' }}
                                        @if ($entry->note)
                                            · {{ $entry->note }}
                                        @endif
                                    </div>
                                </li>
                            @endforeach
                        </ul>
                    @endif
                </div>
            </div>
        </div>

        <div class="col-12 col-lg-4">
            <div class="card border-0 shadow-sm">
                <div class="card-header bg-white py-3 border-0 d-flex justify-content-between align-items-center">
                    <h2 class="h6 mb-0 fw-semibold">KTM document</h2>
                    <a href="{{ route('api.loans.document', ['id' => $loan->id]) }}"
                       target="_blank"
                       class="btn btn-sm btn-light">
                        <i class="bi bi-download me-1"></i> Download
                    </a>
                </div>
                <div class="card-body p-3 text-center">
                    @if ($isPdf)
                        <div class="border rounded bg-light d-flex flex-column align-items-center justify-content-center"
                             style="height:280px;">
                            <i class="bi bi-file-earmark-pdf display-3 text-danger mb-2"></i>
                            <p class="text-muted small mb-0">PDF document — click Download to view.</p>
                        </div>
                    @else
                        <img src="{{ route('api.loans.document', ['id' => $loan->id]) }}"
                             alt="KTM"
                             class="img-fluid border rounded"
                             style="max-height:320px;">
                    @endif
                </div>
            </div>
        </div>
    </div>

    @if ($loan->status === 'pending')
        <div class="modal fade" id="rejectModal" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog">
                <form method="POST" action="{{ route('admin.loans.reject', $loan) }}" class="modal-content">
                    @csrf
                    <div class="modal-header">
                        <h5 class="modal-title fw-semibold">Reject loan request</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <label for="reject_reason" class="form-label small fw-medium">Reason</label>
                        <textarea id="reject_reason"
                                  name="reject_reason"
                                  class="form-control @error('reject_reason') is-invalid @enderror"
                                  rows="4"
                                  required
                                  minlength="3">{{ old('reject_reason') }}</textarea>
                        @error('reject_reason')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                        <div class="form-text">Visible to the student in their loan history.</div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-light" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-danger">Reject loan</button>
                    </div>
                </form>
            </div>
        </div>
    @endif
@endsection
