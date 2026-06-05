@csrf

<div class="row g-3">
    <div class="col-12">
        <label for="name" class="form-label small fw-medium">Nama lengkap</label>
        <input type="text"
               id="name"
               name="name"
               value="{{ old('name', $user->name ?? '') }}"
               class="form-control @error('name') is-invalid @enderror"
               maxlength="255"
               required>
        @error('name')<div class="invalid-feedback">{{ $message }}</div>@enderror
    </div>

    <div class="col-12">
        <label for="email" class="form-label small fw-medium">Email</label>
        <input type="email"
               id="email"
               name="email"
               value="{{ old('email', $user->email ?? '') }}"
               class="form-control @error('email') is-invalid @enderror"
               maxlength="255"
               required>
        @error('email')<div class="invalid-feedback">{{ $message }}</div>@enderror
        <div class="form-text">Digunakan sebagai login di dashboard web dan aplikasi mobile.</div>
    </div>

    <div class="col-12 col-md-6">
        <label class="form-label small fw-medium d-block">Role</label>
        @php $currentRole = old('role', $user->role ?? 'laboran'); @endphp
        <div class="form-check form-check-inline">
            <input class="form-check-input" type="radio" id="role_admin"
                   name="role" value="admin" @checked($currentRole === 'admin')>
            <label class="form-check-label" for="role_admin">
                <span class="lv-pill" style="background:#e0e7ff;color:#4f46e5;border:1px solid #c7d2fe;">Administrator</span>
            </label>
        </div>
        <div class="form-check form-check-inline">
            <input class="form-check-input" type="radio" id="role_laboran"
                   name="role" value="laboran" @checked($currentRole === 'laboran')>
            <label class="form-check-label" for="role_laboran">
                <span class="lv-pill" style="background:#d1fae5;color:#065f46;border:1px solid #6ee7b7;">Laboran</span>
            </label>
        </div>
        @error('role')<div class="text-danger small">{{ $message }}</div>@enderror
    </div>

    <div class="col-12 col-md-6">
        <label class="form-label small fw-medium d-block">Status</label>
        @php $currentStatus = old('status', $user->status ?? 'active'); @endphp
        <div class="form-check form-check-inline">
            <input class="form-check-input" type="radio" id="status_active"
                   name="status" value="active" @checked($currentStatus === 'active')>
            <label class="form-check-label" for="status_active">
                <span class="badge text-bg-success">Aktif</span>
            </label>
        </div>
        <div class="form-check form-check-inline">
            <input class="form-check-input" type="radio" id="status_inactive"
                   name="status" value="inactive" @checked($currentStatus === 'inactive')>
            <label class="form-check-label" for="status_inactive">
                <span class="badge text-bg-secondary">Nonaktif</span>
            </label>
        </div>
        @error('status')<div class="text-danger small">{{ $message }}</div>@enderror
    </div>

    <div class="col-12">
        <hr style="border-color:#f0f2f8;margin:4px 0;">
    </div>

    <div class="col-12 col-md-6">
        <label for="password" class="form-label small fw-medium">
            {{ ($isCreate ?? false) ? 'Kata sandi' : 'Kata sandi baru' }}
        </label>
        <input type="password"
               id="password"
               name="password"
               class="form-control @error('password') is-invalid @enderror"
               minlength="8"
               autocomplete="new-password"
               @if ($isCreate ?? false) required @endif>
        @error('password')<div class="invalid-feedback">{{ $message }}</div>@enderror
        @if (! ($isCreate ?? false))
            <div class="form-text">Biarkan kosong untuk mempertahankan kata sandi saat ini.</div>
        @endif
    </div>

    <div class="col-12 col-md-6">
        <label for="password_confirmation" class="form-label small fw-medium">
            Konfirmasi kata sandi
        </label>
        <input type="password"
               id="password_confirmation"
               name="password_confirmation"
               class="form-control"
               minlength="8"
               autocomplete="new-password"
               @if ($isCreate ?? false) required @endif>
    </div>
</div>

<div style="display:flex;justify-content:flex-end;gap:10px;margin-top:20px;padding-top:16px;border-top:1px solid #f0f2f8;">
    <a href="{{ route('admin.staff-users.index') }}" class="btn btn-ghost btn-sm">Batal</a>
    <button type="submit" class="btn btn-primary btn-sm">
        <i class="bi bi-check-lg me-1"></i>{{ $submitLabel ?? 'Simpan' }}
    </button>
</div>
