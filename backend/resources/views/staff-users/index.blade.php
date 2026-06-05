@extends('layouts.admin')
@section('title', 'Akun Staf')

@section('content')
    <div class="lv-page-header">
        <div>
            <h1>Akun Staf</h1>
            <p>Kelola akun admin dan laboran yang memiliki akses ke dashboard.</p>
        </div>
        {{-- Button opens the password-verify modal --}}
        <button type="button" class="btn btn-primary btn-sm" data-bs-toggle="modal" data-bs-target="#verifyModal">
            <i class="bi bi-person-plus-fill me-1"></i> Tambah Staf
        </button>
    </div>

    <div class="lv-card">
        <div class="lv-card-header" style="background:#f0f3ff;">
            <form method="GET" class="lv-filters">
                <div class="lv-filter-field" style="flex:1;min-width:200px;">
                    <label class="form-label" for="search">Cari</label>
                    <input type="search" id="search" name="search" value="{{ $search }}"
                           class="form-control form-control-sm" placeholder="Nama atau email…">
                </div>
                <div style="display:flex;gap:8px;align-items:flex-end;">
                    <button class="btn btn-apply btn-sm" type="submit">
                        <i class="bi bi-search me-1"></i>Cari
                    </button>
                    @if ($search !== '')
                        <a href="{{ route('admin.staff-users.index') }}" class="btn btn-ghost btn-sm">Bersihkan</a>
                    @endif
                </div>
            </form>
        </div>

        @if ($users->isEmpty())
            <div class="lv-empty">
                <i class="bi bi-person-gear"></i>
                <p>Tidak ada akun staf{{ $search ? ' untuk "'.$search.'"' : '' }}.</p>
            </div>
        @else
            <div style="overflow-x:auto;">
                <table class="lv-table">
                    <thead>
                        <tr>
                            <th>Nama</th>
                            <th>Email</th>
                            <th>Role</th>
                            <th>Status</th>
                            <th style="text-align:right;">Aksi</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($users as $u)
                            <tr>
                                <td>
                                    <div style="display:flex;align-items:center;gap:10px;">
                                        <div style="width:34px;height:34px;border-radius:10px;background:{{ $u->isAdmin() ? '#e0e7ff' : '#d1fae5' }};display:flex;align-items:center;justify-content:center;flex-shrink:0;">
                                            <i class="bi bi-person-fill" style="color:{{ $u->isAdmin() ? '#4f46e5' : '#059669' }};font-size:.85rem;"></i>
                                        </div>
                                        <span style="font-weight:600;">{{ $u->name }}</span>
                                        @if ($u->id === auth()->id())
                                            <span class="lv-pill" style="background:#f3f4f6;color:#6b7280;font-size:.68rem;padding:2px 8px;">Anda</span>
                                        @endif
                                    </div>
                                </td>
                                <td style="color:#6b7280;font-size:.78rem;">{{ $u->email }}</td>
                                <td>
                                    @if ($u->isAdmin())
                                        <span class="lv-pill" style="background:#e0e7ff;color:#4f46e5;border:1px solid #c7d2fe;">Administrator</span>
                                    @else
                                        <span class="lv-pill" style="background:#d1fae5;color:#065f46;border:1px solid #6ee7b7;">Laboran</span>
                                    @endif
                                </td>
                                <td>
                                    @if ($u->status === 'active')
                                        <span class="lv-pill lv-pill-active">Aktif</span>
                                    @else
                                        <span class="lv-pill lv-pill-inactive">Nonaktif</span>
                                    @endif
                                </td>
                                <td style="text-align:right;">
                                    <div class="lv-actions">
                                        <a href="{{ route('admin.staff-users.edit', $u) }}"
                                           class="lv-btn-edit" title="Edit">
                                            <i class="bi bi-pencil"></i>
                                        </a>
                                        @if ($u->id !== auth()->id())
                                            <form method="POST"
                                                  action="{{ route('admin.staff-users.destroy', $u) }}"
                                                  data-confirm="Hapus akun {{ $u->name }}? Tindakan ini tidak dapat dibatalkan."
                                                  data-confirm-title="Hapus akun staf"
                                                  data-confirm-yes="Ya, hapus"
                                                  data-confirm-tone="danger">
                                                @csrf @method('DELETE')
                                                <button type="submit" class="lv-btn-delete" title="Hapus">
                                                    <i class="bi bi-trash"></i>
                                                </button>
                                            </form>
                                        @else
                                            {{-- Can't delete own account --}}
                                            <button type="button" class="lv-btn-delete" disabled
                                                    title="Tidak dapat menghapus akun Anda sendiri">
                                                <i class="bi bi-trash"></i>
                                            </button>
                                        @endif
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

    {{-- ── Password verification modal ─────────────────────────────── --}}
    <div class="modal fade" id="verifyModal" tabindex="-1" aria-labelledby="verifyModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered" style="max-width:420px;">
            <div class="modal-content" style="border-radius:18px;border:none;box-shadow:0 8px 32px rgba(0,0,0,.14);">
                <div class="modal-header" style="border-bottom:1px solid #f0f2f8;padding:20px 24px 14px;">
                    <h5 class="modal-title" id="verifyModalLabel" style="font-weight:700;font-size:1rem;">
                        <i class="bi bi-shield-lock-fill me-2 text-primary"></i>Verifikasi Identitas
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Tutup"></button>
                </div>
                <div class="modal-body" style="padding:20px 24px;">
                    <p style="font-size:.85rem;color:#6b7280;margin-bottom:16px;">
                        Masukkan kata sandi Anda untuk memverifikasi bahwa Anda berwenang menambahkan akun staf baru.
                    </p>
                    <div>
                        <label for="verify_password" class="form-label small fw-medium">Kata Sandi Anda</label>
                        <div style="position:relative;">
                            <input type="password" id="verify_password"
                                   class="form-control"
                                   placeholder="••••••••"
                                   autocomplete="current-password">
                            <button type="button" id="toggleVerifyPw"
                                    style="position:absolute;right:10px;top:50%;transform:translateY(-50%);background:none;border:none;color:#9ca3af;cursor:pointer;padding:0;">
                                <i class="bi bi-eye" id="toggleVerifyIcon"></i>
                            </button>
                        </div>
                        <div id="verifyError" class="text-danger small mt-1" style="display:none;"></div>
                    </div>
                </div>
                <div class="modal-footer" style="border-top:1px solid #f0f2f8;padding:14px 24px 18px;gap:8px;">
                    <button type="button" class="btn btn-ghost btn-sm" data-bs-dismiss="modal">Batal</button>
                    <button type="button" id="verifyBtn" class="btn btn-primary btn-sm">
                        <span id="verifyBtnText"><i class="bi bi-check-lg me-1"></i>Verifikasi &amp; Lanjutkan</span>
                        <span id="verifyBtnSpinner" style="display:none;">
                            <span class="spinner-border spinner-border-sm me-1"></span>Memverifikasi…
                        </span>
                    </button>
                </div>
            </div>
        </div>
    </div>
@endsection

@push('scripts')
<script>
(function () {
    const pwInput   = document.getElementById('verify_password');
    const errorEl   = document.getElementById('verifyError');
    const btn       = document.getElementById('verifyBtn');
    const btnText   = document.getElementById('verifyBtnText');
    const spinner   = document.getElementById('verifyBtnSpinner');
    const toggleBtn = document.getElementById('toggleVerifyPw');
    const toggleIco = document.getElementById('toggleVerifyIcon');
    const modal     = document.getElementById('verifyModal');

    // Reset the modal when it opens
    modal.addEventListener('show.bs.modal', () => {
        pwInput.value = '';
        errorEl.style.display = 'none';
        errorEl.textContent   = '';
        pwInput.classList.remove('is-invalid');
    });

    // Auto-focus the password field when modal is fully visible
    modal.addEventListener('shown.bs.modal', () => pwInput.focus());

    // Show/hide password toggle
    toggleBtn.addEventListener('click', () => {
        const isHidden = pwInput.type === 'password';
        pwInput.type = isHidden ? 'text' : 'password';
        toggleIco.className = isHidden ? 'bi bi-eye-slash' : 'bi bi-eye';
    });

    // Allow Enter key to submit
    pwInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') { e.preventDefault(); btn.click(); }
    });

    btn.addEventListener('click', async () => {
        const pw = pwInput.value.trim();
        if (!pw) {
            showError('Masukkan kata sandi Anda terlebih dahulu.');
            return;
        }

        setLoading(true);

        try {
            const res = await fetch('{{ route('admin.staff-users.verify-password') }}', {
                method : 'POST',
                headers: {
                    'Content-Type'     : 'application/json',
                    'Accept'           : 'application/json',
                    'X-CSRF-TOKEN'     : document.querySelector('meta[name="csrf-token"]').content,
                    'X-Requested-With' : 'XMLHttpRequest',
                },
                body: JSON.stringify({ password: pw }),
            });

            const data = await res.json();

            if (data.ok) {
                // Verification passed → go to the create form
                window.location.href = '{{ route('admin.staff-users.create') }}';
            } else {
                showError(data.message || 'Kata sandi salah.');
                pwInput.value = '';
                pwInput.focus();
            }
        } catch (err) {
            showError('Terjadi kesalahan. Silakan coba lagi.');
        } finally {
            setLoading(false);
        }
    });

    function showError(msg) {
        errorEl.textContent   = msg;
        errorEl.style.display = 'block';
        pwInput.classList.add('is-invalid');
    }

    function setLoading(on) {
        btn.disabled          = on;
        btnText.style.display = on ? 'none'   : '';
        spinner.style.display = on ? ''       : 'none';
    }
})();
</script>
@endpush
