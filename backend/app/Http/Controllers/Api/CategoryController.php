<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CategoryResource;
use App\Models\Category;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

/**
 * Mobile-facing read-only category endpoint. Used by the Flutter app to
 * populate the inventory category filter dropdown.
 *
 * Validates Requirements 7.2 (filter UI source).
 */
class CategoryController extends Controller
{
    public function index(): JsonResponse
    {
        $categories = Category::query()->orderBy('name')->get();

        return ApiResponse::ok(
            CategoryResource::collection($categories),
            'OK',
        );
    }
}
