@extends('layouts.admin')

@section('title', 'Edit student')

@section('content')
    <nav aria-label="breadcrumb" class="mb-3">
        <ol class="breadcrumb small mb-0">
            <li class="breadcrumb-item"><a href="{{ route('admin.users.index') }}">Students</a></li>
            <li class="breadcrumb-item active" aria-current="page">{{ $user->name }}</li>
        </ol>
    </nav>

    <h1 class="h4 mb-4 fw-semibold">Edit student</h1>

    <div class="card border-0 shadow-sm" style="max-width:680px;">
        <div class="card-body p-4">
            <form method="POST" action="{{ route('admin.users.update', $user) }}" novalidate>
                @method('PUT')
                @include('users._form', [
                    'submitLabel' => 'Save changes',
                    'isCreate' => false,
                ])
            </form>
        </div>
    </div>
@endsection
