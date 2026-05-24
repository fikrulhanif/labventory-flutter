@extends('layouts.admin')

@section('title', 'Edit category')

@section('content')
    <nav aria-label="breadcrumb" class="mb-3">
        <ol class="breadcrumb small mb-0">
            <li class="breadcrumb-item"><a href="{{ route('admin.categories.index') }}">Categories</a></li>
            <li class="breadcrumb-item active" aria-current="page">{{ $category->name }}</li>
        </ol>
    </nav>

    <h1 class="h4 mb-4 fw-semibold">Edit category</h1>

    <div class="card border-0 shadow-sm" style="max-width:560px;">
        <div class="card-body p-4">
            <form method="POST" action="{{ route('admin.categories.update', $category) }}" novalidate>
                @method('PUT')
                @include('categories._form', ['submitLabel' => 'Save changes'])
            </form>
        </div>
    </div>
@endsection
