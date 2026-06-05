@extends('layouts.admin')

@section('title', 'Mahasiswa')

@section('content')
    <div class="lv-page-header">
        <div>
            <h1>Mahasiswa</h1>
            <p>Kelola akun mahasiswa yang dapat meminjam inventaris.</p>
        </div>
        <a href="{{ route('admin.users.create') }}" class="btn btn-primary btn-sm">
            <i class="bi bi-person-plus-fill me-1"></i> Tambah Mahasiswa
        </a>
    </div>

    <div class="lv-card">
        <div class="lv-card-header" style="background:#f0f3ff;">
            <form method="GET" class="lv-filters">
                <div class="lv-filter-field" style="flex:1;min-width:200px;">
                    <label class="form-label" for="search">Cari</label>
                    <input type="search" id="search" name="search" value="{{ $search }}"
                           class="form-control form-control-sm" placeholder="Nama, NIM, atau email…">
                </div>
                <div style="display:flex;gap:8px;align-items:flex-end;">
                    <button class="btn btn-apply btn-sm" type="submit">
                        <i class="bi bi-search me-1"></i>Cari
                    </button>
                    @if ($search !== '')
                        <a href="{{ route('admin.users.index') }}" class="btn btn-ghost btn-sm">Bersihkan</a>
                    @endif
                </div>
            </form>
        </div>

        @if ($users->isEmpty())
            <div class="lv-empty">
                <i class="bi bi-people"></i>
                <p>Tidak ada mahasiswa{{ $search ? ' untuk "'.$search.'"' : '' }}.</p>
            </div>
        @else
            <div style="overflow-x:auto;">
                <table class="lv-table">
                    <thead>
                        <tr>
                            <th>Mahasiswa</th>
                            <th>NIM</th>
                            <th>Email</th>
                            <th>Status</th>
                            <th style="text-align:center;">Pinjaman Aktif</th>
                            <th style="text-align:right;">Aksi</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($users as $user)
                            <tr>
                                <td>
                                    <a href="{{ route('admin.users.show', $user) }}"
                                       style="font-weight:600;color:#111827;text-decoration:none;">
                                        {{ $user->name }}
                                    </a>
                                </td>
                                <td><code>{{ $user->nim }}</code></td>
                                <td style="color:#6b7280;font-size:.78rem;">{{ $user->email }}</td>
                                <td>
                                    @if ($user->status === 'active')
                                        <span class="lv-pill lv-pill-active">Aktif</span>
                                    @else
                                        <span class="lv-pill lv-pill-inactive">Nonaktif</span>
                                    @endif
                                </td>
                                <td style="text-align:center;">
                                    <span style="font-weight:700;font-size:.88rem;color:{{ $user->active_loans_count > 0 ? '#7c3aed' : '#9ca3af' }}">
                                        {{ $user->active_loans_count }}
                                    </span>
                                </td>
                                <td style="text-align:right;">
                                    <div class="lv-actions">
                                        <a href="{{ route('admin.users.show', $user) }}" class="lv-btn-view" title="View history">
                                            <i class="bi bi-eye"></i>
                                        </a>
                                        <a href="{{ route('admin.users.edit', $user) }}" class="lv-btn-edit" title="Edit">
                                            <i class="bi bi-pencil"></i>
                                        </a>
                                        <form method="POST" action="{{ route('admin.users.destroy', $user) }}"
                                              data-confirm="Hapus {{ $user->name }}? Tindakan ini tidak dapat dibatalkan."
                                              data-confirm-title="Hapus mahasiswa"
                                              data-confirm-yes="Ya, hapus"
                                              data-confirm-tone="danger">
                                            @csrf @method('DELETE')
                                            <button type="submit"
                                                    class="lv-btn-delete"
                                                    {{ $user->active_loans_count > 0 ? 'disabled' : '' }}
                                                    title="{{ $user->active_loans_count > 0 ? 'Tidak dapat dihapus: ada peminjaman aktif' : 'Hapus' }}">
                                                <i class="bi bi-trash"></i>
                                            </button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif

        @if ($users->hasPages())
            <div style="padding:14px 20px;border-top:1px solid #f0f2f8;">
                {{ $users->links() }}
            </div>
        @endif
    </div>
@endsection
