@extends('layouts.admin')

@section('title', 'Dashboard')

@section('content')
    <div class="d-flex align-items-center justify-content-between mb-4">
        <div>
            <h1 class="h4 mb-1 fw-semibold">Dashboard</h1>
            <p class="text-muted small mb-0">Lab inventory at a glance.</p>
        </div>
    </div>

    <div class="card border-0 shadow-sm">
        <div class="card-body p-4">
            <p class="mb-0 text-muted">
                Statistics and recent loans will land here in the next task.
            </p>
        </div>
    </div>
@endsection
