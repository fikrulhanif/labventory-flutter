@extends('layouts.admin')
@section('title', 'Mahasiswa Baru')
@section('content')
    <nav aria-label="breadcrumb" style="margin-bottom:16px;">
        <ol class="breadcrumb" style="font-size:.75rem;margin:0;">
            <li class="breadcrumb-item"><a href="{{ route('admin.users.index') }}">Mahasiswa</a></li>
            <li class="breadcrumb-item active">Baru</li>
        </ol>
    </nav>
    <div class="lv-page-header">
        <div><h1>Akun Mahasiswa Baru</h1><p>Buat login mahasiswa yang dikelola.</p></div>
        <a href="{{ route('admin.users.index') }}" class="btn btn-ghost btn-sm"><i class="bi bi-arrow-left me-1"></i>Kembali</a>
    </div>
    <div class="lv-card" style="max-width:680px;">
        <div class="lv-card-header"><span class="lv-card-title"><i class="bi bi-person-plus me-2 text-primary"></i>Detail mahasiswa</span></div>
        <div style="padding:24px;">
            <form method="POST" action="{{ route('admin.users.store') }}" novalidate>
                @include('users._form', ['submitLabel'=>'Buat mahasiswa','isCreate'=>true])
            </form>
        </div>
    </div>
@endsection
