@extends('layouts.admin')

@section('title', 'Kategori')

@section('content')
    <div class="lv-page-header">
        <div>
            <h1>Kategori</h1>
            <p>Kelompokkan inventaris berdasarkan jenis.</p>
        </div>
        <a href="{{ route('admin.categories.create') }}" class="btn btn-primary btn-sm">
            <i class="bi bi-plus-lg me-1"></i> Tambah Kategori
        </a>
    </div>

    <div class="lv-card">
        <div class="lv-card-header" style="background:#f0f3ff;">
            <form method="GET" class="lv-filters">
                <div class="lv-filter-field" style="flex:1;">
                    <label class="form-label" for="search">Cari</label>
                    <input type="search" id="search" name="search" value="{{ $search }}"
                           class="form-control form-control-sm" placeholder="Nama kategori…">
                </div>
                <div style="display:flex;gap:8px;align-items:flex-end;">
                    <button class="btn btn-apply btn-sm" type="submit">
                        <i class="bi bi-search me-1"></i>Cari
                    </button>
                    @if ($search !== '')
                        <a href="{{ route('admin.categories.index') }}" class="btn btn-ghost btn-sm">Bersihkan</a>
                    @endif
                </div>
            </form>
        </div>

        @if ($categories->isEmpty())
            <div class="lv-empty">
                <i class="bi bi-tags"></i>
                <p>Belum ada kategori. Buat yang pertama.</p>
            </div>
        @else
            <div style="overflow-x:auto;">
                <table class="lv-table">
                    <thead>
                        <tr>
                            <th>Nama</th>
                            <th style="text-align:center;">Inventaris</th>
                            <th>Dibuat</th>
                            <th style="text-align:right;">Aksi</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($categories as $category)
                            <tr>
                                <td style="font-weight:600;">{{ $category->name }}</td>
                                <td style="text-align:center;">
                                    <span style="font-weight:700;font-size:.88rem;color:{{ $category->inventories_count > 0 ? '#6366f1' : '#9ca3af' }}">
                                        {{ $category->inventories_count }}
                                    </span>
                                </td>
                                <td style="font-size:.78rem;color:#9ca3af;">
                                    {{ $category->created_at?->format('d M Y') }}
                                </td>
                                <td style="text-align:right;">
                                    <div class="lv-actions">
                                        <a href="{{ route('admin.categories.edit', $category) }}"
                                           class="lv-btn-edit" title="Edit">
                                            <i class="bi bi-pencil"></i>
                                        </a>
                                        <form method="POST" action="{{ route('admin.categories.destroy', $category) }}"
                                              data-confirm="Hapus '{{ $category->name }}'? Tindakan ini tidak dapat dibatalkan."
                                              data-confirm-title="Hapus kategori"
                                              data-confirm-yes="Ya, hapus"
                                              data-confirm-tone="danger">
                                            @csrf @method('DELETE')
                                            <button type="submit" class="lv-btn-delete">
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

        @if ($categories->hasPages())
            <div style="padding:14px 20px;border-top:1px solid #f0f2f8;">
                {{ $categories->links() }}
            </div>
        @endif
    </div>
@endsection
