@extends('layouts.admin')

@section('title', 'Peminjaman')

@php
    $statusTabs = [
        ''          => ['Semua', 'all'],
        'pending'   => ['Menunggu',  'lv-pill-pending'],
        'approved'  => ['Disetujui', 'lv-pill-approved'],
        'borrowed'  => ['Dipinjam', 'lv-pill-borrowed'],
        'returned'  => ['Dikembalikan', 'lv-pill-returned'],
        'rejected'  => ['Ditolak', 'lv-pill-rejected'],
    ];
@endphp

@section('content')
    <div class="lv-page-header">
        <div>
            <h1>Permintaan Peminjaman</h1>
            <p>Kelola dan proses permintaan peminjaman mahasiswa.</p>
        </div>
    </div>

    <div class="lv-card">
        {{-- Single tab-style filter — no dropdown duplication --}}
        <div style="padding:14px 20px;border-bottom:1.5px solid #d8dcea;background:#f0f3ff;display:flex;flex-wrap:wrap;gap:6px;align-items:center;">
            <span style="font-size:.70rem;font-weight:700;color:#6b7280;text-transform:uppercase;letter-spacing:.06em;margin-right:4px;">Filter:</span>
            @foreach ($statusTabs as $val => [$label, $cls])
                <a href="{{ route('admin.loans.index', $val ? ['status' => $val] : []) }}"
                   style="display:inline-flex;align-items:center;gap:5px;padding:5px 14px;border-radius:999px;font-size:.75rem;font-weight:700;text-decoration:none;transition:all .14s;
                          {{ $selectedStatus === $val
                              ? 'background:#1e2334;color:#fff;border:1.5px solid #1e2334;'
                              : 'background:#fff;color:#374151;border:1.5px solid #c8cedd;' }}">
                    @if ($val)
                        <span style="width:5px;height:5px;border-radius:50%;background:{{ match($val) {
                            'pending'  => '#b45309',
                            'approved' => '#0e7490',
                            'borrowed' => '#6d28d9',
                            'returned' => '#065f46',
                            'rejected' => '#374151',
                            default    => '#6b7280',
                        } }};display:inline-block;"></span>
                    @endif
                    {{ $label }}
                    @if ($selectedStatus === $val && $val)
                        <span style="background:rgba(255,255,255,.25);border-radius:999px;padding:0 5px;font-size:.65rem;">✕</span>
                    @endif
                </a>
            @endforeach
        </div>

        @if ($loans->isEmpty())
            <div class="lv-empty">
                <i class="bi bi-clipboard"></i>
                <p>Tidak ada permintaan peminjaman{{ $selectedStatus ? ' dengan status '.$selectedStatus : '' }}.</p>
            </div>
        @else
            <div style="overflow-x:auto;">
                <table class="lv-table">
                    <thead>
                        <tr>
                            <th>Mahasiswa</th>
                            <th>Inventaris</th>
                            <th>Periode</th>
                            <th>Status</th>
                            <th>Dikirim</th>
                            <th style="text-align:right;">Aksi</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($loans as $loan)
                            <tr>
                                <td>
                                    <div style="font-weight:600;">{{ $loan->user?->name ?? '—' }}</div>
                                    <div style="font-size:.72rem;color:#9ca3af;"><code>{{ $loan->user?->nim ?? '' }}</code></div>
                                </td>
                                <td>
                                    <div style="font-weight:600;">{{ $loan->inventory?->name ?? '—' }}</div>
                                    <div style="font-size:.72rem;"><code>{{ $loan->inventory?->code ?? '' }}</code></div>
                                </td>
                                <td style="font-size:.78rem;color:#6b7280;white-space:nowrap;">
                                    {{ $loan->borrow_date?->toDateString() }}
                                    <span style="opacity:.45;">→</span>
                                    {{ $loan->return_date?->toDateString() }}
                                </td>
                                <td><span class="lv-pill lv-pill-{{ $loan->status }}">{{ ucfirst($loan->status) }}</span></td>
                                <td style="font-size:.78rem;color:#9ca3af;">{{ $loan->created_at?->diffForHumans() }}</td>
                                <td style="text-align:right;">
                                    <a href="{{ route('admin.loans.show', $loan) }}" class="btn btn-primary btn-sm">
                                        <i class="bi bi-eye me-1"></i>Tinjau
                                    </a>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif

        @if ($loans->hasPages())
            <div style="padding:14px 20px;border-top:1px solid #ebedf8;">
                {{ $loans->links() }}
            </div>
        @endif
    </div>
@endsection
