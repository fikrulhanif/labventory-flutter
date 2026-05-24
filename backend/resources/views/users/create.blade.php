@extends('layouts.admin')

@section('title', 'New student')

@section('content')
    <nav aria-label="breadcrumb" class="mb-3">
        <ol class="breadcrumb small mb-0">
            <li class="breadcrumb-item"><a href="{{ route('admin.users.index') }}">Students</a></li>
            <li class="breadcrumb-item active" aria-current="page">New</li>
        </ol>
    </nav>

    <h1 class="h4 mb-4 fw-semibold">New student account</h1>

    <div class="card border-0 shadow-sm" style="max-width:680px;">
        <div class="card-body p-4">
            <form method="POST" action="{{ route('admin.users.store') }}" novalidate>
                @include('users._form', [
                    'submitLabel' => 'Create student',
                    'isCreate' => true,
                ])
            </form>
        </div>
    </div>
@endsection
