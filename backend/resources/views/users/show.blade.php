@extends('layouts.admin')

@section('title', $user->name)

@php
    $toneMap = [
        'pending'  => 'lv-pill-pending',
        'approved' => 'lv-pill-approved',
        'borrowed' => 'lv-pill-borrowed',
        'returned' => 'lv-pill-returned',
        'rejected' => 'lv-pill-rejected',
    ];
    $statusOptions = ['pending'=>'Menunggu','approved'=>'Disetujui','borrowed'=>'Dipinjam','returned'=>'Dikembalikan','rejected'=>'Ditolak'];
@endphp

@section('content')
    <nav aria-label="breadcrumb" style="margin-bottom:16px;">
        <ol class="breadcrumb" style="font-size:.75rem;margin:0;">
            <li class="breadcrumb-item"><a href="{{ route('admin.users.index') }}">Mahasiswa</a></li>
            <li class="breadcrumb-item active">{{ $user->name }}</li>
        </ol>
    </nav>

    <div class="lv-page-header">
        <div>
            <h1>{{ $user->name }}</h1>
            <p>Profil mahasiswa dan riwayat peminjaman.</p>
        </div>
        <a href="{{ route('admin.users.edit', $user) }}" class="btn btn-ghost btn-sm">
            <i class="bi bi-pencil me-1"></i>Edit
        </a>
    </div>

    <div class="row g-4 mb-4">
        {{-- Profile card --}}
        <div class="col-12 col-lg-4">
            <div class="lv-card" style="height:100%;">
                <div class="lv-card-header">
                    <span class="lv-card-title"><i class="bi bi-person-circle me-2 text-primary"></i>Profil</span>
                    @if ($user->status === 'active')
                        <span class="lv-pill lv-pill-active">Aktif</span>
                    @else
                        <span class="lv-pill lv-pill-inactive">Nonaktif</span>
                    @endif
                </div>
                <div style="padding:20px;">
                    <div style="display:flex;align-items:center;gap:14px;margin-bottom:18px;">
                        <div style="width:56px;height:56px;border-radius:50%;background:linear-gradient(135deg,#6366f1,#7c3aed);display:flex;align-items:center;justify-content:center;color:#fff;font-weight:800;font-size:1.3rem;flex-shrink:0;">
                            {{ strtoupper(substr($user->name, 0, 1)) }}
                        </div>
                        <div>
                            <div style="font-weight:700;color:#111827;font-size:.95rem;">{{ $user->name }}</div>
                            <div style="font-size:.75rem;color:#9ca3af;">{{ $user->email }}</div>
                        </div>
                    </div>
                    <hr style="border-color:#f0f2f8;margin:0 0 16px;">
                    <div style="display:grid;gap:10px;">
                        @foreach ([
                            ['NIM',       $user->nim ?? '—',  'bi-badge-id'],
                            ['Email',     $user->email,       'bi-envelope'],
                            ['Peran',     ucfirst($user->role), 'bi-shield'],
                            ['Bergabung', $user->created_at?->format('d M Y'), 'bi-calendar'],
                        ] as [$label, $value, $icon])
                            <div style="display:flex;align-items:center;gap:10px;">
                                <div style="width:28px;height:28px;border-radius:8px;background:#f1f3f9;display:flex;align-items:center;justify-content:center;flex-shrink:0;">
                                    <i class="bi {{ $icon }}" style="font-size:.75rem;color:#6366f1;"></i>
                                </div>
                                <div>
                                    <div style="font-size:.68rem;text-transform:uppercase;letter-spacing:.07em;color:#9ca3af;font-weight:700;">{{ $label }}</div>
                                    <div style="font-size:.82rem;color:#374151;font-weight:600;">{{ $value }}</div>
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>
            </div>
        </div>

        {{-- Stats --}}
        <div class="col-12 col-lg-8">
            <div class="lv-card" style="height:100%;">
                <div class="lv-card-header">
                    <span class="lv-card-title"><i class="bi bi-graph-up me-2 text-primary"></i>Statistik Peminjaman</span>
                </div>
                <div style="padding:20px;">
                    @php
                        $statItems = [
                            ['Total',         $stats['total'],    '#6366f1'],
                            ['Menunggu',      $stats['pending'],  '#f59e0b'],
                            ['Disetujui',     $stats['approved'], '#0891b2'],
                            ['Dipinjam',      $stats['borrowed'], '#7c3aed'],
                            ['Dikembalikan',  $stats['returned'], '#10b981'],
                            ['Ditolak',       $stats['rejected'], '#6b7280'],
                        ];
                    @endphp
                    <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:10px;">
                        @foreach ($statItems as [$label, $value, $color])
                            <div style="padding:14px 16px;border-radius:14px;border:1px solid #e8eaf0;border-left:3px solid {{ $color }};">
                                <div style="font-size:.68rem;text-transform:uppercase;letter-spacing:.07em;color:#9ca3af;font-weight:700;margin-bottom:4px;">{{ $label }}</div>
                                <div style="font-size:1.6rem;font-weight:800;color:#111827;letter-spacing:-.03em;">{{ number_format($value) }}</div>
                            </div>
                        @endforeach
                    </div>
                </div>
            </div>
        </div>
    </div>

    {{-- Loan history --}}
    <div class="lv-card">
        <div class="lv-card-header">
            <span class="lv-card-title"><i class="bi bi-list-check me-2 text-primary"></i>Riwayat Peminjaman</span>
            <form method="GET" style="display:flex;align-items:center;gap:8px;">
                <label style="font-size:.75rem;color:#6b7280;font-weight:600;white-space:nowrap;">Filter</label>
                <select name="status" class="form-select form-select-sm" onchange="this.form.submit()" style="min-width:130px;">
                    <option value="">Semua status</option>
                    @foreach ($statusOptions as $val => $label)
                        <option value="{{ $val }}" @selected($status === $val)>{{ $label }}</option>
                    @endforeach
                </select>
                @if ($status !== '')
                    <a href="{{ route('admin.users.show', $user) }}" class="btn btn-ghost btn-sm">Bersihkan</a>
                @endif
            </form>
        </div>

        @if ($loans->isEmpty())
            <div class="lv-empty">
                <i class="bi bi-clipboard"></i>
                <p>Tidak ada peminjaman {{ $status ? $status.' ' : '' }}yang ditemukan untuk mahasiswa ini.</p>
            </div>
        @else
            <div style="overflow-x:auto;">
                <table class="lv-table">
                    <thead>
                        <tr>
                            <th>Inventaris</th>
                            <th>Periode</th>
                            <th>Status</th>
                            <th>Diambil</th>
                            <th>Dikembalikan</th>
                            <th>Dikirim</th>
                            <th style="text-align:right;">Aksi</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($loans as $loan)
                            <tr>
                                <td>
                                    <div style="font-weight:600;">{{ $loan->inventory?->name ?? '—' }}</div>
                                    <div style="font-size:.72rem;"><code>{{ $loan->inventory?->code ?? '' }}</code></div>
                                </td>
                                <td style="font-size:.78rem;color:#6b7280;white-space:nowrap;">
                                    {{ $loan->borrow_date?->toDateString() }} → {{ $loan->return_date?->toDateString() }}
                                </td>
                                <td><span class="lv-pill {{ $toneMap[$loan->status] ?? 'lv-pill-rejected' }}">{{ ucfirst($loan->status) }}</span></td>
                                <td style="font-size:.75rem;color:#9ca3af;">{{ $loan->picked_up_at?->format('d M Y') ?? '—' }}</td>
                                <td style="font-size:.75rem;color:#9ca3af;">{{ $loan->returned_at?->format('d M Y') ?? '—' }}</td>
                                <td style="font-size:.75rem;color:#9ca3af;">{{ $loan->created_at?->diffForHumans() }}</td>
                                <td style="text-align:right;">
                                    <a href="{{ route('admin.loans.show', $loan) }}" class="btn btn-ghost btn-sm">
                                        <i class="bi bi-eye"></i>
                                    </a>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif

        @if ($loans->hasPages())
            <div style="padding:14px 20px;border-top:1px solid #f0f2f8;">
                {{ $loans->links() }}
            </div>
        @endif
    </div>
@endsection
