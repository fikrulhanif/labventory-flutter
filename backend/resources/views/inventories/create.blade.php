@extends('layouts.admin')

@section('title', 'New inventory')

@section('content')
    <nav aria-label="breadcrumb" style="margin-bottom:16px;">
        <ol class="breadcrumb" style="font-size:.75rem;margin:0;">
            <li class="breadcrumb-item"><a href="{{ route('admin.inventories.index') }}">Inventories</a></li>
            <li class="breadcrumb-item active">New item</li>
        </ol>
    </nav>

    <div class="lv-page-header">
        <div><h1>New inventory item</h1><p>Add equipment to the catalog.</p></div>
        <a href="{{ route('admin.inventories.index') }}" class="btn btn-ghost btn-sm">
            <i class="bi bi-arrow-left me-1"></i>Back
        </a>
    </div>

    <div class="lv-card">
        <div class="lv-card-header">
            <span class="lv-card-title"><i class="bi bi-plus-circle me-2 text-primary"></i>Item details</span>
        </div>
        <div style="padding:24px;">
            <form method="POST" action="{{ route('admin.inventories.store') }}" enctype="multipart/form-data" novalidate>
                @include('inventories._form', ['submitLabel' => 'Create item'])
            </form>
        </div>
    </div>
@endsection
