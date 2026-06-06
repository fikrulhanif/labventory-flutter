<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\InventoryController;
use App\Http\Controllers\Api\LoanController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\Admin\AdminInventoryController;
use App\Http\Controllers\Api\Admin\AdminLoanController;
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

    // KTM streaming — owner or staff (Requirement 18.6)
    Route::get('/loans/{id}/document', [LoanController::class, 'document'])
        ->whereNumber('id')
        ->name('api.loans.document');

    // Student-only loan endpoints (Requirements 8, 11)
    Route::middleware('role:student')->group(function (): void {
        Route::get('/loans', [LoanController::class, 'index'])->name('api.loans.index');
        Route::post('/loans', [LoanController::class, 'store'])->name('api.loans.store');
        Route::get('/loans/{id}', [LoanController::class, 'show'])
            ->whereNumber('id')
            ->name('api.loans.show');
    });

    // ── Notification center (in-app, database-backed, no push/FCM) ──
    // Accessible to all authenticated users (students and staff).
    Route::prefix('notifications')->name('api.notifications.')->group(function (): void {
        Route::get('/', [NotificationController::class, 'index'])->name('index');
        Route::get('/unread-count', [NotificationController::class, 'unreadCount'])->name('unread-count');
        Route::post('/read-all', [NotificationController::class, 'markAllRead'])->name('read-all');
        Route::post('/{id}/read', [NotificationController::class, 'markRead'])
            ->whereNumber('id')
            ->name('read');
    });
});

/*
|--------------------------------------------------------------------------
| Admin mobile operations (RBAC) — Requirements 19-22
|--------------------------------------------------------------------------
|
| Staff (admin/laboran) operate the QR handover/return workflow from the
| same Flutter app. These endpoints reuse LoanService::markPickedUp /
| markReturned, so the stock-conservation invariant holds identically on
| both the web dashboard and the mobile admin flow. Students hitting these
| routes get HTTP 403 from the role middleware (Req 20.3, 21.5, 22.8).
|
| {code} matches inventories.code exactly (the bare QR payload, Req 15.1);
| {loan} is numeric.
*/
Route::middleware(['auth:sanctum', 'role:admin,laboran'])
    ->prefix('admin')
    ->group(function (): void {
        Route::get('/inventories/{code}', [AdminInventoryController::class, 'lookup'])
            ->name('api.admin.inventories.lookup');
        Route::get('/inventories/{code}/loans', [AdminInventoryController::class, 'loans'])
            ->name('api.admin.inventories.loans');

        Route::post('/loans/{loan}/handover', [AdminLoanController::class, 'handover'])
            ->whereNumber('loan')
            ->name('api.admin.loans.handover');
        Route::post('/loans/{loan}/return', [AdminLoanController::class, 'return'])
            ->whereNumber('loan')
            ->name('api.admin.loans.return');
    });
