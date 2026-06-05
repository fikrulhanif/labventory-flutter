@extends('layouts.admin')
@section('title', 'Edit · '.$category->name)
@section('content')
    <nav aria-label="breadcrumb" style="margin-bottom:16px;">
        <ol class="breadcrumb" style="font-size:.75rem;margin:0;">
            <li class="breadcrumb-item"><a href="{{ route('admin.categories.index') }}">Kategori</a></li>
            <li class="breadcrumb-item active">{{ $category->name }}</li>
        </ol>
    </nav>
    <div class="lv-page-header">
        <div><h1>Edit kategori</h1><p>{{ $category->name }}</p></div>
        <a href="{{ route('admin.categories.index') }}" class="btn btn-ghost btn-sm"><i class="bi bi-arrow-left me-1"></i>Kembali</a>
    </div>
    <div class="lv-card" style="max-width:520px;">
        <div class="lv-card-header"><span class="lv-card-title"><i class="bi bi-pencil me-2 text-primary"></i>Edit detail</span></div>
        <div style="padding:24px;">
            <form method="POST" action="{{ route('admin.categories.update', $category) }}" novalidate>
                @method('PUT')
                @include('categories._form', ['submitLabel' => 'Simpan Perubahan'])
            </form>
        </div>
    </div>
@endsection
