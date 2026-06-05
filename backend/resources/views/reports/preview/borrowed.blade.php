@extends('reports.preview.layout')

@section('title', 'Inventaris Sedang Dipinjam')
@section('toolbar-meta', 'Dibuat ' . $generatedAt->toDayDateTimeString() . ' UTC')
@section('report-subtitle', 'Snapshot barang yang sedang dipinjam dari lab.')
@section('download-url', route('admin.reports.borrowed'))

@section('content')
    <div class="report-meta">
        <div class="meta-chip">
            <div class="meta-chip-icon" style="background:#6d28d9;"><i class="bi bi-box-arrow-right"></i></div>
            <div>
                <div class="meta-chip-label">Barang keluar</div>
                <div class="meta-chip-value">{{ number_format($totalItems) }}</div>
            </div>
        </div>
        <div class="meta-chip">
            <div class="meta-chip-icon" style="background:#0ea5e9;"><i class="bi bi-arrow-left-right"></i></div>
            <div>
                <div class="meta-chip-label">Pinjaman aktif</div>
                <div class="meta-chip-value">{{ number_format($totalBorrowed) }}</div>
            </div>
        </div>
    </div>

    <div class="section-title"><i class="bi bi-box-arrow-right" style="color:#6d28d9;"></i>Barang sedang dipinjam</div>

    <table class="report-table">
        <thead>
            <tr>
                <th style="width:12%;">Kode</th>
                <th style="width:20%;">Alat</th>
                <th style="width:14%;">Kategori</th>
                <th class="num" style="width:8%;">Stok</th>
                <th class="num" style="width:9%;">Keluar</th>
                <th>Peminjam</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($rows as $row)
                <tr>
                    <td><code>{{ $row['inventory']?->code }}</code></td>
                    <td><strong>{{ $row['inventory']?->name }}</strong></td>
                    <td>{{ $row['inventory']?->category?->name ?? '—' }}</td>
                    <td class="num">{{ number_format($row['available_count']) }}</td>
                    <td class="num"><strong style="color:#6d28d9;">{{ number_format($row['borrowed_count']) }}</strong></td>
                    <td>
                        <ul style="margin:0;padding:0;list-style:none;">
                            @foreach ($row['loans'] as $loan)
                                <li style="padding:3px 0;border-top:1px dashed #ebedf8;font-size:.78rem;">
                                    <strong>{{ $loan->user?->name ?? '—' }}</strong>
                                    <span style="color:#9ca3af;"><code>{{ $loan->user?->nim ?? '' }}</code></span>
                                    &nbsp;·&nbsp;
                                    {{ $loan->borrow_date?->toDateString() }} → {{ $loan->return_date?->toDateString() }}
                                </li>
                            @endforeach
                        </ul>
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="6">
                        <div class="empty-state">
                            <i class="bi bi-check2-all"></i>
                            <p>Tidak ada inventaris yang sedang dipinjam.</p>
                        </div>
                    </td>
                </tr>
            @endforelse
        </tbody>
    </table>
@endsection
