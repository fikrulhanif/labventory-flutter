@extends('layouts.admin')

@section('title', 'Loan #'.$loan->id)

@php
    $documentExt = strtolower(pathinfo($loan->document, PATHINFO_EXTENSION));
    $isPdf = $documentExt === 'pdf';

    $toneMap = [
        'pending'  => 'lv-pill-pending',
        'approved' => 'lv-pill-approved',
        'borrowed' => 'lv-pill-borrowed',
        'returned' => 'lv-pill-returned',
        'rejected' => 'lv-pill-rejected',
    ];

    $historyTone = [
        'pending'  => '#f59e0b',
        'approved' => '#0891b2',
        'borrowed' => '#7c3aed',
        'returned' => '#16a34a',
        'rejected' => '#6b7280',
    ];
@endphp

@section('content')
    {{-- Breadcrumb --}}
    <nav aria-label="breadcrumb" style="margin-bottom:16px;">
        <ol class="breadcrumb" style="font-size:.75rem;margin:0;">
            <li class="breadcrumb-item"><a href="{{ route('admin.loans.index') }}">Peminjaman</a></li>
            <li class="breadcrumb-item active">#{{ $loan->id }}</li>
        </ol>
    </nav>

    <div class="lv-page-header">
        <div style="display:flex;align-items:center;gap:12px;flex-wrap:wrap;">
            <div>
                <h1>Peminjaman #{{ $loan->id }}</h1>
                <p>Dikirim {{ $loan->created_at?->diffForHumans() }}</p>
            </div>
            <span class="lv-pill {{ $toneMap[$loan->status] ?? 'lv-pill-rejected' }}" style="font-size:.75rem;">
                {{ ucfirst($loan->status) }}
            </span>
        </div>

        {{-- Action buttons --}}
        <div style="display:flex;gap:8px;flex-wrap:wrap;">
            @if ($loan->status === 'pending')
                <form method="POST" action="{{ route('admin.loans.approve', $loan) }}"
                      data-confirm="Setujui permintaan peminjaman untuk {{ $loan->user?->name }}?"
                      data-confirm-title="Setujui Peminjaman"
                      data-confirm-yes="Ya, setujui"
                      data-confirm-tone="info">
                    @csrf
                    <button class="btn btn-sm" style="background:#0ea5e9;color:#fff;border:none;">
                        <i class="bi bi-check-lg me-1"></i>Setujui
                    </button>
                </form>
                <button class="btn btn-sm"
                        style="background:#fef2f2;border:1px solid #fecaca;color:#dc2626;"
                        onclick="lvShowRejectModal()">
                    <i class="bi bi-x-lg me-1"></i>Tolak
                </button>
            @elseif ($loan->status === 'approved')
                <form method="POST" action="{{ route('admin.loans.pickup', $loan) }}"
                      data-confirm="Tandai sudah diambil? Stok akan berkurang 1."
                      data-confirm-title="Tandai Sudah Diambil"
                      data-confirm-yes="Ya, lanjutkan"
                      data-confirm-tone="warning">
                    @csrf
                    <button class="btn btn-primary btn-sm">
                        <i class="bi bi-box-arrow-up-right me-1"></i>Tandai Sudah Diambil
                    </button>
                </form>
            @elseif ($loan->status === 'borrowed')
                <form method="POST" action="{{ route('admin.loans.return', $loan) }}"
                      data-confirm="Tandai sudah dikembalikan? Stok akan bertambah 1."
                      data-confirm-title="Tandai Sudah Dikembalikan"
                      data-confirm-yes="Ya, lanjutkan"
                      data-confirm-tone="info">
                    @csrf
                    <button class="btn btn-sm" style="background:#10b981;color:#fff;border:none;">
                        <i class="bi bi-arrow-counterclockwise me-1"></i>Tandai Sudah Dikembalikan
                    </button>
                </form>
            @endif
            <a href="{{ route('admin.loans.index') }}" class="btn btn-ghost btn-sm">
                <i class="bi bi-arrow-left me-1"></i>Kembali
            </a>
        </div>
    </div>

    <div class="row g-4">
        {{-- Left: details + history --}}
        <div class="col-12 col-lg-8">

            {{-- Student + inventory card --}}
            <div class="lv-card" style="margin-bottom:16px;">
                <div class="lv-card-header" style="background:linear-gradient(135deg,#1e2334,#2d3748);">
                    <span class="lv-card-title" style="color:#e5e7eb;"><i class="bi bi-info-circle me-2"></i>Detail Permintaan</span>
                    <span class="lv-pill lv-pill-{{ $loan->status }}">{{ ucfirst($loan->status) }}</span>
                </div>
                <div style="padding:20px;">
                    <div class="row g-4">
                        {{-- Student --}}
                        <div class="col-12 col-sm-6">
                            <div style="font-size:.70rem;font-weight:700;text-transform:uppercase;letter-spacing:.07em;color:#9ca3af;margin-bottom:8px;">Mahasiswa</div>
                            <div style="display:flex;align-items:center;gap:10px;">
                                <div style="width:40px;height:40px;border-radius:50%;background:linear-gradient(135deg,#6366f1,#7c3aed);display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:.85rem;flex-shrink:0;">
                                    {{ strtoupper(substr($loan->user?->name ?? '?', 0, 1)) }}
                                </div>
                                <div>
                                    <a href="{{ route('admin.users.show', $loan->user) }}"
                                       style="font-weight:600;color:#111827;text-decoration:none;">
                                        {{ $loan->user?->name ?? '—' }}
                                    </a>
                                    <div style="font-size:.72rem;color:#9ca3af;">NIM <code>{{ $loan->user?->nim ?? '—' }}</code></div>
                                    <div style="font-size:.72rem;color:#9ca3af;">{{ $loan->user?->email ?? '' }}</div>
                                </div>
                            </div>
                        </div>
                        {{-- Inventory --}}
                        <div class="col-12 col-sm-6">
                            <div style="font-size:.70rem;font-weight:700;text-transform:uppercase;letter-spacing:.07em;color:#9ca3af;margin-bottom:8px;">Inventaris</div>
                            <a href="{{ route('admin.inventories.show', $loan->inventory) }}"
                               style="font-weight:600;color:#111827;text-decoration:none;">
                                {{ $loan->inventory?->name ?? '—' }}
                            </a>
                            <div style="font-size:.72rem;color:#9ca3af;margin-top:2px;">
                                <code>{{ $loan->inventory?->code ?? '' }}</code>
                                · {{ $loan->inventory?->category?->name ?? '—' }}
                                · Stok sekarang: <strong>{{ $loan->inventory?->stock ?? 0 }}</strong>
                            </div>
                        </div>
                    </div>

                    <hr style="border-color:#f0f2f8;margin:16px 0;">

                    {{-- Dates grid --}}
                    <div class="row g-3">
                        @php
                            $cells = [
                                ['Tanggal pinjam',  $loan->borrow_date?->toDateString()],
                                ['Tanggal kembali', $loan->return_date?->toDateString()],
                                ['Diambil pada',    $loan->picked_up_at?->toDayDateTimeString()],
                                ['Dikembalikan pada', $loan->returned_at?->toDayDateTimeString()],
                            ];
                        @endphp
                        @foreach ($cells as [$label, $value])
                            @if ($value)
                                <div class="col-6 col-md-3">
                                    <div style="font-size:.70rem;font-weight:700;text-transform:uppercase;color:#9ca3af;margin-bottom:3px;">{{ $label }}</div>
                                    <div style="font-size:.82rem;color:#374151;font-weight:600;">{{ $value }}</div>
                                </div>
                            @endif
                        @endforeach
                    </div>

                    @if ($loan->notes)
                        <div style="margin-top:14px;padding:12px 14px;background:#f8f9ff;border-radius:12px;border:1px solid #e8eaf0;">
                            <div style="font-size:.70rem;font-weight:700;text-transform:uppercase;color:#9ca3af;margin-bottom:4px;">Catatan</div>
                            <div style="font-size:.83rem;color:#374151;">{{ $loan->notes }}</div>
                        </div>
                    @endif

                    @if ($loan->reject_reason)
                        <div style="margin-top:14px;padding:12px 14px;background:#fef2f2;border-radius:12px;border:1px solid #fecaca;">
                            <div style="font-size:.70rem;font-weight:700;text-transform:uppercase;color:#dc2626;margin-bottom:4px;"><i class="bi bi-exclamation-triangle-fill me-1"></i>Alasan Penolakan</div>
                            <div style="font-size:.83rem;color:#991b1b;">{{ $loan->reject_reason }}</div>
                        </div>
                    @endif
                </div>
            </div>

            {{-- Status history --}}
            <div class="lv-card">
                <div class="lv-card-header" style="background:linear-gradient(135deg,#1e2334,#2d3748);">
                    <span class="lv-card-title" style="color:#e5e7eb;"><i class="bi bi-clock-history me-2"></i>Riwayat Status</span>
                </div>
                @if ($loan->statusHistory->isEmpty())
                    <div class="lv-empty" style="padding:28px 20px;">
                        <i class="bi bi-hourglass" style="font-size:1.5rem;opacity:.35;display:block;margin-bottom:6px;"></i>
                        <p>Belum ada perubahan status.</p>
                    </div>
                @else
                    <div style="padding:8px 20px 12px;">
                        @foreach ($loan->statusHistory->sortByDesc('created_at') as $entry)
                            <div style="display:flex;align-items:flex-start;gap:12px;padding:10px 0;border-bottom:1px solid #f0f2f8;">
                                <div style="width:28px;height:28px;border-radius:50%;background:{{ $historyTone[$entry->to_status] ?? '#9ca3af' }}1a;display:flex;align-items:center;justify-content:center;flex-shrink:0;margin-top:1px;">
                                    <div style="width:8px;height:8px;border-radius:50%;background:{{ $historyTone[$entry->to_status] ?? '#9ca3af' }};"></div>
                                </div>
                                <div style="flex:1;">
                                    <div style="display:flex;align-items:center;gap:6px;flex-wrap:wrap;">
                                        <span class="lv-pill {{ $toneMap[$entry->from_status] ?? 'lv-pill-rejected' }}">{{ ucfirst($entry->from_status) }}</span>
                                        <i class="bi bi-arrow-right" style="color:#9ca3af;font-size:.7rem;"></i>
                                        <span class="lv-pill {{ $toneMap[$entry->to_status] ?? 'lv-pill-rejected' }}">{{ ucfirst($entry->to_status) }}</span>
                                    </div>
                                    <div style="font-size:.72rem;color:#9ca3af;margin-top:3px;">
                                        oleh {{ $entry->actor?->name ?? 'sistem' }}
                                        @if ($entry->note) · {{ $entry->note }} @endif
                                    </div>
                                </div>
                                <div style="font-size:.72rem;color:#9ca3af;white-space:nowrap;">
                                    {{ $entry->created_at?->diffForHumans() }}
                                </div>
                            </div>
                        @endforeach
                    </div>
                @endif
            </div>
        </div>

        {{-- Right: KTM --}}
        <div class="col-12 col-lg-4">
            <div class="lv-card">
                <div class="lv-card-header" style="background:linear-gradient(135deg,#1e1b4b,#312e81);">
                    <span class="lv-card-title" style="color:#e0e7ff;"><i class="bi bi-card-image me-2"></i>Dokumen KTM</span>
                    <a href="{{ route('admin.loans.document', $loan) }}"
                       target="_blank"
                       class="btn btn-sm"
                       style="background:rgba(255,255,255,.15);border:1px solid rgba(255,255,255,.25);color:#fff;">
                        <i class="bi bi-download me-1"></i>Unduh
                    </a>
                </div>
                <div style="padding:16px;text-align:center;background:#fafbff;">
                    @if ($isPdf)
                        <div style="height:280px;background:#f0f0ff;border-radius:12px;border:1.5px solid #c8cedd;display:flex;flex-direction:column;align-items:center;justify-content:center;">
                            <i class="bi bi-file-earmark-pdf" style="font-size:3rem;color:#ef4444;margin-bottom:8px;"></i>
                            <p style="font-size:.78rem;color:#9ca3af;margin:0 0 12px;">Dokumen PDF</p>
                            <a href="{{ route('admin.loans.document', $loan) }}"
                               target="_blank"
                               class="btn btn-primary btn-sm">
                                <i class="bi bi-box-arrow-up-right me-1"></i>Buka PDF
                            </a>
                        </div>
                    @else
                        <a href="{{ route('admin.loans.document', $loan) }}" target="_blank">
                            <img src="{{ route('admin.loans.document', $loan) }}"
                                 alt="KTM"
                                 style="max-width:100%;border-radius:12px;border:1.5px solid #c8cedd;max-height:340px;cursor:zoom-in;transition:transform .2s;"
                                 onmouseover="this.style.transform='scale(1.02)'"
                                 onmouseout="this.style.transform='scale(1)'">
                        </a>
                        <p style="font-size:.70rem;color:#9ca3af;margin:8px 0 0;">Klik untuk membuka ukuran penuh</p>
                    @endif
                </div>
            </div>
        </div>
    </div>

    {{-- Reject modal (triggered via JS) --}}
    @if ($loan->status === 'pending')
        <div id="lv-reject-overlay"
             style="display:none;position:fixed;inset:0;background:rgba(15,22,35,.55);z-index:9999;align-items:center;justify-content:center;">
            <div style="background:#fff;border-radius:20px;padding:28px;width:100%;max-width:420px;box-shadow:0 24px 64px rgba(0,0,0,.2);margin:20px;">
                <h3 style="font-size:1.05rem;font-weight:800;color:#111827;margin:0 0 6px;">Tolak permintaan peminjaman</h3>
                <p style="font-size:.82rem;color:#6b7280;margin:0 0 18px;">Alasan akan terlihat oleh mahasiswa di riwayat peminjaman mereka.</p>
                <form method="POST" action="{{ route('admin.loans.reject', $loan) }}" id="lv-reject-form">
                    @csrf
                    <textarea id="reject_reason" name="reject_reason"
                              style="width:100%;padding:10px 14px;border:1.5px solid #e5e7eb;border-radius:12px;font-size:.85rem;font-family:inherit;resize:vertical;min-height:90px;outline:none;transition:border-color .15s;"
                              placeholder="Masukkan alasan penolakan…" required minlength="3">{{ old('reject_reason') }}</textarea>
                    @error('reject_reason')
                        <div style="font-size:.73rem;color:#ef4444;margin-top:4px;">{{ $message }}</div>
                    @enderror
                    <div style="display:flex;gap:10px;margin-top:16px;">
                        <button type="button" class="btn btn-ghost btn-sm" onclick="lvHideRejectModal()" style="flex:1;">Batal</button>
                        <button type="submit" class="btn btn-sm" style="flex:1;background:#ef4444;color:#fff;border:none;">
                            <i class="bi bi-x-lg me-1"></i>Tolak peminjaman
                        </button>
                    </div>
                </form>
            </div>
        </div>
    @endif
@endsection

@push('scripts')
<script>
function lvShowRejectModal() {
    document.getElementById('lv-reject-overlay').style.display = 'flex';
}
function lvHideRejectModal() {
    document.getElementById('lv-reject-overlay').style.display = 'none';
}
document.getElementById('lv-reject-overlay')?.addEventListener('click', function(e) {
    if (e.target === this) lvHideRejectModal();
});
</script>
@endpush
