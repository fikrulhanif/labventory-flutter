@extends('reports.preview.layout')

@section('title', 'Inventaris Terpopuler')
@section('toolbar-meta',
    $startDate->toDateString() . ' → ' . $endDate->toDateString() .
    ' · top ' . $limit .
    ' · dibuat ' . $generatedAt->toDayDateTimeString() . ' UTC')
@section('report-subtitle', 'Top ' . $limit . ' inventaris paling banyak diminta dalam periode ini.')
@section('download-url',
    route('admin.reports.popular', [
        'start_date' => $startDate->toDateString(),
        'end_date'   => $endDate->toDateString(),
    ]))

@section('content')
    <div class="report-meta">
        <div class="meta-chip">
            <div class="meta-chip-icon" style="background:#f59e0b;"><i class="bi bi-trophy"></i></div>
            <div>
                <div class="meta-chip-label">Barang diurutkan</div>
                <div class="meta-chip-value">{{ number_format($rows->count()) }}</div>
            </div>
        </div>
        <div class="meta-chip">
            <div class="meta-chip-icon" style="background:#6366f1;"><i class="bi bi-clipboard-data"></i></div>
            <div>
                <div class="meta-chip-label">Total peminjaman</div>
                <div class="meta-chip-value">{{ number_format($totalLoans) }}</div>
            </div>
        </div>
        <div class="meta-chip">
            <div class="meta-chip-icon" style="background:#0ea5e9;"><i class="bi bi-calendar-range"></i></div>
            <div>
                <div class="meta-chip-label">Rentang tanggal</div>
                <div class="meta-chip-value" style="font-size:.72rem;font-weight:700;">{{ $startDate->toDateString() }} → {{ $endDate->toDateString() }}</div>
            </div>
        </div>
    </div>

    <div class="section-title"><i class="bi bi-bar-chart" style="color:#f59e0b;"></i>Peringkat</div>

    <table class="report-table">
        <thead>
            <tr>
                <th style="width:8%;text-align:center;">#</th>
                <th style="width:16%;">Kode</th>
                <th>Nama alat</th>
                <th style="width:22%;">Kategori</th>
                <th class="num" style="width:14%;">Jumlah Pinjaman</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($rows as $row)
                <tr>
                    <td style="text-align:center;">
                        @if ($row['rank'] <= 3)
                            <span style="font-size:1rem;">{{ ['🥇','🥈','🥉'][$row['rank']-1] }}</span>
                        @else
                            <span style="font-weight:700;color:#6b7280;">{{ $row['rank'] }}</span>
                        @endif
                    </td>
                    <td><code>{{ $row['inventory']?->code ?? '—' }}</code></td>
                    <td><strong>{{ $row['inventory']?->name ?? '—' }}</strong></td>
                    <td>{{ $row['inventory']?->category?->name ?? '—' }}</td>
                    <td class="num">
                        <span style="font-size:1.05rem;font-weight:800;color:#6366f1;">{{ number_format($row['loan_count']) }}</span>
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="5">
                        <div class="empty-state">
                            <i class="bi bi-clipboard"></i>
                            <p>Tidak ada peminjaman dalam rentang tanggal ini.</p>
                        </div>
                    </td>
                </tr>
            @endforelse
        </tbody>
    </table>
@endsection
