@extends('layouts.admin')

@section('title', 'New inventory')

@section('content')
    <nav aria-label="breadcrumb" class="mb-3">
        <ol class="breadcrumb small mb-0">
            <li class="breadcrumb-item"><a href="{{ route('admin.inventories.index') }}">Inventories</a></li>
            <li class="breadcrumb-item active" aria-current="page">New</li>
        </ol>
    </nav>

    <h1 class="h4 mb-4 fw-semibold">New inventory item</h1>

    <div class="card border-0 shadow-sm">
        <div class="card-body p-4 p-md-5">
            <form method="POST"
                  action="{{ route('admin.inventories.store') }}"
                  enctype="multipart/form-data"
                  novalidate>
                @include('inventories._form', ['submitLabel' => 'Create item'])
            </form>
        </div>
    </div>
@endsection
