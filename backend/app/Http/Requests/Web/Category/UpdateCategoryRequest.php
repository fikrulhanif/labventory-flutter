<?php

namespace App\Http\Requests\Web\Category;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Validates PUT/PATCH /admin/categories/{category} (Requirements 5.1, 5.2,
 * 5.3, 5.4). The unique rule ignores the current row so saving without
 * changing the name does not trip the uniqueness check.
 */
class UpdateCategoryRequest extends FormRequest
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
        $category = $this->route('category');
        $id = is_object($category) ? $category->id : $category;

        return [
            'name' => [
                'required',
                'string',
                'max:100',
                Rule::unique('categories', 'name')->ignore($id),
            ],
        ];
    }
}
