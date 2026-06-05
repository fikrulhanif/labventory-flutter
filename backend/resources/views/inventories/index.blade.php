@extends('layouts.admin')

@section('title', 'Inventaris')

@section('content')
    <div class="lv-page-header">
        <div>
            <h1>Inventaris</h1>
            <p>Katalog alat yang tersedia untuk dipinjam.</p>
        </div>
        <a href="{{ route('admin.inventories.create') }}" class="btn btn-primary btn-sm">
            <i class="bi bi-plus-lg me-1"></i> Tambah Inventaris
        </a>
    </div>

    <div class="lv-card">
        {{-- Filters --}}
        <div class="lv-card-header" style="background:#f0f3ff;">
            <form method="GET" class="lv-filters">
                <div class="lv-filter-field">
                    <label class="form-label" for="search">Cari</label>
                    <input type="search" id="search" name="search" value="{{ $search }}"
                           class="form-control form-control-sm" placeholder="Nama atau kode…">
                </div>
                <div class="lv-filter-field">
                    <label class="form-label" for="category_id">Kategori</label>
                    <select id="category_id" name="category_id" class="form-select form-select-sm">
                        <option value="">Semua kategori</option>
                        @foreach ($categories as $cat)
                            <option value="{{ $cat->id }}" @selected((string)$selectedCategory===(string)$cat->id)>
                                {{ $cat->name }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <div class="lv-filter-field">
                    <label class="form-label" for="status">Status</label>
                    <select id="status" name="status" class="form-select form-select-sm">
                        <option value="">Semua</option>
                        <option value="available" @selected($selectedStatus==='available')>Tersedia</option>
                        <option value="out_of_stock" @selected($selectedStatus==='out_of_stock')>Stok Habis</option>
                    </select>
                </div>
                <div style="display:flex;gap:8px;align-items:flex-end;">
                    <button class="btn btn-apply btn-sm" type="submit">
                        <i class="bi bi-funnel me-1"></i>Filter
                    </button>
                    @if ($search||$selectedCategory||$selectedStatus)
                        <a href="{{ route('admin.inventories.index') }}" class="btn btn-ghost btn-sm">Atur Ulang</a>
                    @endif
                </div>
            </form>
        </div>

        @if ($inventories->isEmpty())
            <div class="lv-empty">
                <i class="bi bi-boxes"></i>
                <p>Tidak ada inventaris yang sesuai filter.</p>
            </div>
        @else
            <div style="overflow-x:auto;">
                <table class="lv-table">
                    <thead>
                        <tr>
                            <th>Alat</th>
                            <th>Kode</th>
                            <th>Kategori</th>
                            <th style="text-align:center;">Stok</th>
                            <th>Status</th>
                            <th style="text-align:right;">Aksi</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($inventories as $inv)
                            <tr>
                                <td>
                                    <div style="display:flex;align-items:center;gap:10px;">
                                        @if ($inv->image_url)
                                            <img src="{{ $inv->image_url }}" alt="" class="lv-thumb">
                                        @else
                                            <div class="lv-thumb-placeholder">
                                                <i class="bi bi-image"></i>
                                            </div>
                                        @endif
                                        <div>
                                            <div style="font-weight:600;">{{ $inv->name }}</div>
                                            <div style="font-size:.72rem;color:#9ca3af;">{{ \Illuminate\Support\Str::limit($inv->description, 55) }}</div>
                                        </div>
                                    </div>
                                </td>
                                <td><code>{{ $inv->code }}</code></td>
                                <td style="color:#6b7280;">{{ $inv->category?->name ?? '—' }}</td>
                                <td style="text-align:center;">
                                    <span style="font-weight:700;font-size:.9rem;">{{ $inv->stock }}</span>
                                </td>
                                <td>
                                    @if ($inv->status === 'available')
                                        <span class="lv-pill lv-pill-available">Tersedia</span>
                                    @else
                                        <span class="lv-pill lv-pill-out">Stok Habis</span>
                                    @endif
                                </td>
                                <td style="text-align:right;">
                                    <div class="lv-actions">
                                        <a href="{{ route('admin.inventories.show', $inv) }}" class="lv-btn-view" title="View">
                                            <i class="bi bi-eye"></i>
                                        </a>
                                        <a href="{{ route('admin.inventories.edit', $inv) }}" class="lv-btn-edit" title="Edit">
                                            <i class="bi bi-pencil"></i>
                                        </a>
                                        <form method="POST" action="{{ route('admin.inventories.destroy', $inv) }}"
                                              data-confirm="Hapus '{{ $inv->name }}'? Tindakan ini tidak dapat dibatalkan."
                                              data-confirm-title="Hapus inventaris"
                                              data-confirm-yes="Ya, hapus"
                                              data-confirm-tone="danger">
                                            @csrf @method('DELETE')
                                            <button type="submit" class="lv-btn-delete" title="Delete">
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

        @if ($inventories->hasPages())
            <div style="padding:14px 20px;border-top:1px solid #f0f2f8;">
                {{ $inventories->links() }}
            </div>
        @endif
    </div>
@endsection
