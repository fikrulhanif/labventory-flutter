@csrf

<div class="row g-3">
    <div class="col-12 col-md-6">
        <label for="name" class="form-label small fw-medium">Full name</label>
        <input type="text"
               id="name"
               name="name"
               value="{{ old('name', $user->name ?? '') }}"
               class="form-control @error('name') is-invalid @enderror"
               maxlength="255"
               required>
        @error('name')<div class="invalid-feedback">{{ $message }}</div>@enderror
    </div>

    <div class="col-12 col-md-6">
        <label for="nim" class="form-label small fw-medium">NIM</label>
        <input type="text"
               id="nim"
               name="nim"
               value="{{ old('nim', $user->nim ?? '') }}"
               class="form-control @error('nim') is-invalid @enderror"
               maxlength="32"
               required>
        @error('nim')<div class="invalid-feedback">{{ $message }}</div>@enderror
        <div class="form-text">Used as the student's mobile login identifier.</div>
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
    </div>

    <div class="col-12 col-md-6">
        <label for="password" class="form-label small fw-medium">
            {{ ($isCreate ?? false) ? 'Password' : 'New password' }}
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
            <div class="form-text">Leave blank to keep the current password.</div>
        @endif
    </div>

    <div class="col-12 col-md-6">
        <label for="password_confirmation" class="form-label small fw-medium">Confirm password</label>
        <input type="password"
               id="password_confirmation"
               name="password_confirmation"
               class="form-control"
               minlength="8"
               autocomplete="new-password"
               @if ($isCreate ?? false) required @endif>
    </div>

    <div class="col-12">
        <label class="form-label small fw-medium d-block">Status</label>
        @php
            $current = old('status', $user->status ?? 'active');
        @endphp
        <div class="form-check form-check-inline">
            <input class="form-check-input"
                   type="radio"
                   id="status_active"
                   name="status"
                   value="active"
                   @checked($current === 'active')>
            <label class="form-check-label" for="status_active">
                <span class="badge text-bg-success">Active</span>
            </label>
        </div>
        <div class="form-check form-check-inline">
            <input class="form-check-input"
                   type="radio"
                   id="status_inactive"
                   name="status"
                   value="inactive"
                   @checked($current === 'inactive')>
            <label class="form-check-label" for="status_inactive">
                <span class="badge text-bg-secondary">Inactive</span>
            </label>
        </div>
        <div class="form-text">Switching to <strong>inactive</strong> will sign this student out of the mobile app immediately.</div>
        @error('status')<div class="text-danger small">{{ $message }}</div>@enderror
    </div>
</div>

<div class="d-flex justify-content-end gap-2 mt-4">
    <a href="{{ route('admin.users.index') }}" class="btn btn-light">Cancel</a>
    <button type="submit" class="btn btn-primary">{{ $submitLabel ?? 'Save' }}</button>
</div>
