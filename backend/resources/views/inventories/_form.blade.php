@csrf

<div class="row g-4">
    <div class="col-12 col-lg-8">
        <div class="row g-3">
            <div class="col-12 col-md-6">
                <label for="name" class="form-label small fw-medium">Name</label>
                <input type="text"
                       id="name"
                       name="name"
                       value="{{ old('name', $inventory->name ?? '') }}"
                       class="form-control @error('name') is-invalid @enderror"
                       maxlength="255"
                       required>
                @error('name')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>

            <div class="col-12 col-md-6">
                <label for="code" class="form-label small fw-medium">Inventory code</label>
                <input type="text"
                       id="code"
                       name="code"
                       value="{{ old('code', $inventory->code ?? '') }}"
                       class="form-control @error('code') is-invalid @enderror"
                       maxlength="50"
                       placeholder="INV-001"
                       required>
                @error('code')<div class="invalid-feedback">{{ $message }}</div>@enderror
                <div class="form-text">Used by the QR code. Must be unique.</div>
            </div>

            <div class="col-12 col-md-6">
                <label for="category_id" class="form-label small fw-medium">Category</label>
                <select id="category_id"
                        name="category_id"
                        class="form-select @error('category_id') is-invalid @enderror"
                        required>
                    <option value="">— select a category —</option>
                    @foreach ($categories as $category)
                        <option value="{{ $category->id }}"
                            @selected((int) old('category_id', $inventory->category_id ?? null) === $category->id)>
                            {{ $category->name }}
                        </option>
                    @endforeach
                </select>
                @error('category_id')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>

            <div class="col-12 col-md-6">
                <label for="stock" class="form-label small fw-medium">Stock</label>
                <input type="number"
                       id="stock"
                       name="stock"
                       min="0"
                       value="{{ old('stock', $inventory->stock ?? 0) }}"
                       class="form-control @error('stock') is-invalid @enderror"
                       required>
                @error('stock')<div class="invalid-feedback">{{ $message }}</div>@enderror
                <div class="form-text">Status is derived automatically: available iff stock &gt; 0.</div>
            </div>

            <div class="col-12">
                <label for="description" class="form-label small fw-medium">Description</label>
                <textarea id="description"
                          name="description"
                          rows="4"
                          maxlength="2000"
                          class="form-control @error('description') is-invalid @enderror">{{ old('description', $inventory->description ?? '') }}</textarea>
                @error('description')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>
        </div>
    </div>

    <div class="col-12 col-lg-4">
        <label class="form-label small fw-medium">Image</label>

        @if (! empty($inventory?->image_url))
            <div class="border rounded p-2 mb-2 bg-light text-center">
                <img src="{{ $inventory->image_url }}"
                     alt="Inventory image"
                     class="img-fluid rounded"
                     style="max-height:180px;">
                <div class="text-muted small mt-2">Current image</div>
            </div>
        @endif

        <input type="file"
               id="image"
               name="image"
               accept="image/jpeg,image/png,image/webp"
               class="form-control @error('image') is-invalid @enderror">
        @error('image')<div class="invalid-feedback">{{ $message }}</div>@enderror
        <div class="form-text">JPEG / PNG / WebP up to 2 MB. Optional.</div>
    </div>
</div>

<div style="display:flex;justify-content:flex-end;gap:10px;margin-top:20px;padding-top:16px;border-top:1px solid #f0f2f8;">
    <a href="{{ route('admin.inventories.index') }}" class="btn btn-ghost btn-sm">Cancel</a>
    <button type="submit" class="btn btn-primary btn-sm">
        <i class="bi bi-check-lg me-1"></i>{{ $submitLabel ?? 'Save' }}
    </button>
</div>
