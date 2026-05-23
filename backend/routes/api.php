<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\InventoryController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Labventory API routes
|--------------------------------------------------------------------------
|
| Mobile-facing JSON API. All routes are mounted under /api by
| bootstrap/app.php (Laravel 13 install:api).
|
| Conventions:
|   - Public routes: register, login.
|   - Everything else requires auth:sanctum (Requirement 17.5).
|   - Student-only routes carry the role:student middleware.
|
*/

Route::prefix('auth')->group(function (): void {
    // Public endpoints (Requirement 17.5)
    Route::post('/register', [AuthController::class, 'register'])->name('api.auth.register');
    Route::post('/login', [AuthController::class, 'login'])->name('api.auth.login');

    // Authenticated endpoints
    Route::middleware('auth:sanctum')->group(function (): void {
        Route::post('/logout', [AuthController::class, 'logout'])->name('api.auth.logout');
        Route::get('/me', [AuthController::class, 'me'])->name('api.auth.me');

        // Student-only endpoints (Requirement 12.5)
        Route::middleware('role:student')->group(function (): void {
            Route::patch('/profile', [AuthController::class, 'updateProfile'])->name('api.auth.profile');
        });
    });
});

// Authenticated catalog endpoints (Requirements 7.1 — 7.7)
Route::middleware('auth:sanctum')->group(function (): void {
    Route::get('/categories', [CategoryController::class, 'index'])->name('api.categories.index');
    Route::get('/inventories', [InventoryController::class, 'index'])->name('api.inventories.index');
    Route::get('/inventories/{id}', [InventoryController::class, 'show'])
        ->whereNumber('id')
        ->name('api.inventories.show');
});
