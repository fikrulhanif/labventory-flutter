@extends('layouts.admin')
@section('title', 'Tambah Akun Staf')

@section('content')
    <nav aria-label="breadcrumb" style="margin-bottom:16px;">
        <ol class="breadcrumb" style="font-size:.75rem;margin:0;">
            <li class="breadcrumb-item"><a href="{{ route('admin.staff-users.index') }}">Staf</a></li>
            <li class="breadcrumb-item active">Baru</li>
        </ol>
    </nav>

    <div class="lv-page-header">
        <div>
            <h1>Tambah Akun Staf</h1>
            <p>Buat akun admin atau laboran baru.</p>
        </div>
        <a href="{{ route('admin.staff-users.index') }}" class="btn btn-ghost btn-sm">
            <i class="bi bi-arrow-left me-1"></i>Kembali
        </a>
    </div>

    {{-- Security notice --}}
    <div class="alert" style="background:#fffbeb;border:1px solid #fde68a;border-radius:12px;padding:14px 18px;margin-bottom:18px;display:flex;gap:12px;align-items:flex-start;max-width:680px;">
        <i class="bi bi-shield-exclamation" style="color:#d97706;font-size:1.1rem;flex-shrink:0;margin-top:1px;"></i>
        <div>
            <strong style="font-size:.85rem;color:#92400e;">Akun berpengaruh</strong>
            <p style="font-size:.82rem;color:#92400e;margin:4px 0 0;">
                Akun staf memiliki akses penuh ke dashboard termasuk data mahasiswa, inventaris, dan peminjaman.
                Pastikan hanya orang yang berwenang yang diberi akun ini.
            </p>
        </div>
    </div>

    <div class="lv-card" style="max-width:680px;">
        <div class="lv-card-header">
            <span class="lv-card-title">
                <i class="bi bi-person-gear me-2 text-primary"></i>Detail akun staf
            </span>
        </div>
        <div style="padding:24px;">
            <form method="POST" action="{{ route('admin.staff-users.store') }}" novalidate>
                @include('staff-users._form', ['submitLabel' => 'Buat Akun Staf', 'isCreate' => true, 'user' => null])
            </form>
        </div>
    </div>
@endsection
