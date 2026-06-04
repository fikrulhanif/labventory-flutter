@csrf
<div style="margin-bottom:16px;">
    <label for="name" class="form-label">Category name</label>
    <input type="text" id="name" name="name"
           value="{{ old('name', $category->name ?? '') }}"
           maxlength="100"
           class="form-control @error('name') is-invalid @enderror"
           placeholder="e.g. Microcontroller"
           required autofocus>
    @error('name')<div class="invalid-feedback">{{ $message }}</div>@enderror
    <div style="font-size:.73rem;color:#9ca3af;margin-top:4px;">Up to 100 characters · must be unique.</div>
</div>
<div style="display:flex;justify-content:flex-end;gap:10px;margin-top:20px;padding-top:16px;border-top:1px solid #f0f2f8;">
    <a href="{{ route('admin.categories.index') }}" class="btn btn-ghost btn-sm">Cancel</a>
    <button type="submit" class="btn btn-primary btn-sm">
        <i class="bi bi-check-lg me-1"></i>{{ $submitLabel ?? 'Save' }}
    </button>
</div>
