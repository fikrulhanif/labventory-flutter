@extends('layouts.admin')
@section('title', 'Edit Staf · '.$user->name)

@section('content')
    <nav aria-label="breadcrumb" style="margin-bottom:16px;">
        <ol class="breadcrumb" style="font-size:.75rem;margin:0;">
            <li class="breadcrumb-item"><a href="{{ route('admin.staff-users.index') }}">Staf</a></li>
            <li class="breadcrumb-item active">{{ $user->name }}</li>
        </ol>
    </nav>

    <div class="lv-page-header">
        <div>
            <h1>Edit Akun Staf</h1>
            <p>{{ $user->name }}</p>
        </div>
        <a href="{{ route('admin.staff-users.index') }}" class="btn btn-ghost btn-sm">
            <i class="bi bi-arrow-left me-1"></i>Kembali
        </a>
    </div>

    <div class="lv-card" style="max-width:680px;">
        <div class="lv-card-header">
            <span class="lv-card-title">
                <i class="bi bi-pencil me-2 text-primary"></i>Edit detail
            </span>
        </div>
        <div style="padding:24px;">
            <form method="POST" action="{{ route('admin.staff-users.update', $user) }}" novalidate>
                @method('PUT')
                @include('staff-users._form', ['submitLabel' => 'Simpan Perubahan', 'isCreate' => false])
            </form>
        </div>
    </div>
@endsection
