@extends('layouts.admin')

@section('title', 'Edit inventory')

@section('content')
    <nav aria-label="breadcrumb" class="mb-3">
        <ol class="breadcrumb small mb-0">
            <li class="breadcrumb-item"><a href="{{ route('admin.inventories.index') }}">Inventories</a></li>
            <li class="breadcrumb-item"><a href="{{ route('admin.inventories.show', $inventory) }}">{{ $inventory->code }}</a></li>
            <li class="breadcrumb-item active" aria-current="page">Edit</li>
        </ol>
    </nav>

    <h1 class="h4 mb-4 fw-semibold">Edit inventory</h1>

    <div class="card border-0 shadow-sm">
        <div class="card-body p-4 p-md-5">
            <form method="POST"
                  action="{{ route('admin.inventories.update', $inventory) }}"
                  enctype="multipart/form-data"
                  novalidate>
                @method('PUT')
                @include('inventories._form', ['submitLabel' => 'Save changes'])
            </form>
        </div>
    </div>
@endsection
