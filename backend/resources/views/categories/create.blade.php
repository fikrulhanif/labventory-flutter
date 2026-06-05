@extends('layouts.admin')
@section('title', 'Kategori Baru')
@section('content')
    <nav aria-label="breadcrumb" style="margin-bottom:16px;">
        <ol class="breadcrumb" style="font-size:.75rem;margin:0;">
            <li class="breadcrumb-item"><a href="{{ route('admin.categories.index') }}">Kategori</a></li>
            <li class="breadcrumb-item active">Baru</li>
        </ol>
    </nav>
    <div class="lv-page-header">
        <div><h1>Kategori Baru</h1><p>Tambah kelompok inventaris baru.</p></div>
        <a href="{{ route('admin.categories.index') }}" class="btn btn-ghost btn-sm"><i class="bi bi-arrow-left me-1"></i>Kembali</a>
    </div>
    <div class="lv-card" style="max-width:520px;">
        <div class="lv-card-header"><span class="lv-card-title"><i class="bi bi-tags me-2 text-primary"></i>Detail kategori</span></div>
        <div style="padding:24px;">
            <form method="POST" action="{{ route('admin.categories.store') }}" novalidate>
                @include('categories._form', ['submitLabel' => 'Buat kategori'])
            </form>
        </div>
    </div>
@endsection
