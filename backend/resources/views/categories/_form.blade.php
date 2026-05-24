@csrf

<div class="mb-3">
    <label for="name" class="form-label small fw-medium">Category name</label>
    <input type="text"
           id="name"
           name="name"
           value="{{ old('name', $category->name ?? '') }}"
           maxlength="100"
           class="form-control @error('name') is-invalid @enderror"
           required
           autofocus>
    @error('name')
        <div class="invalid-feedback">{{ $message }}</div>
    @enderror
    <div class="form-text">Up to 100 characters. Must be unique across the catalog.</div>
</div>

<div class="d-flex justify-content-end gap-2">
    <a href="{{ route('admin.categories.index') }}" class="btn btn-light">Cancel</a>
    <button type="submit" class="btn btn-primary">{{ $submitLabel ?? 'Save' }}</button>
</div>
