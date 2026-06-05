@extends('layouts.admin')

@section('title', 'Edit · '.$inventory->name)

@section('content')
    <nav aria-label="breadcrumb" style="margin-bottom:16px;">
        <ol class="breadcrumb" style="font-size:.75rem;margin:0;">
            <li class="breadcrumb-item"><a href="{{ route('admin.inventories.index') }}">Inventaris</a></li>
            <li class="breadcrumb-item"><a href="{{ route('admin.inventories.show', $inventory) }}">{{ $inventory->code }}</a></li>
            <li class="breadcrumb-item active">Edit</li>
        </ol>
    </nav>

    <div class="lv-page-header">
        <div><h1>Edit inventaris</h1><p>{{ $inventory->name }}</p></div>
        <a href="{{ route('admin.inventories.show', $inventory) }}" class="btn btn-ghost btn-sm">
            <i class="bi bi-arrow-left me-1"></i>Kembali
        </a>
    </div>

    <div class="lv-card">
        <div class="lv-card-header">
            <span class="lv-card-title"><i class="bi bi-pencil me-2 text-primary"></i>Edit detail</span>
        </div>
        <div style="padding:24px;">
            <form method="POST" action="{{ route('admin.inventories.update', $inventory) }}" enctype="multipart/form-data" novalidate>
                @method('PUT')
                @include('inventories._form', ['submitLabel' => 'Simpan Perubahan'])
            </form>
        </div>
    </div>
@endsection
