<?php

namespace App\Http\Requests\Web\Inventory;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Validates PUT/PATCH /admin/inventories/{inventory} (Requirements 6.1 — 6.5).
 *
 * `code` uniqueness ignores the current row so saving without changing
 * the code does not trip the unique check.
 */
class UpdateInventoryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        $inventory = $this->route('inventory');
        $id = is_object($inventory) ? $inventory->id : $inventory;

        return [
            'category_id' => ['required', 'integer', 'exists:categories,id'],
            'name' => ['required', 'string', 'max:255'],
            'code' => [
                'required',
                'string',
                'max:50',
                Rule::unique('inventories', 'code')->ignore($id),
            ],
            'stock' => ['required', 'integer', 'min:0'],
            'description' => ['nullable', 'string', 'max:2000'],
            'image' => ['nullable', 'file', 'mimetypes:image/jpeg,image/png,image/webp', 'max:2048'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'category_id.exists' => 'The selected category does not exist.',
            'code.unique' => 'This inventory code is already in use.',
            'image.mimetypes' => 'The image must be a JPEG, PNG, or WebP file.',
            'image.max' => 'The image may not be larger than 2 MB.',
            'stock.min' => 'Stock must be zero or greater.',
        ];
    }
}
