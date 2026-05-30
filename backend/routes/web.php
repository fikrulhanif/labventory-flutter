<?php

use App\Http\Controllers\Web\Auth\LoginController;
use App\Http\Controllers\Web\CategoryController;
use App\Http\Controllers\Web\DashboardController;
use App\Http\Controllers\Web\InventoryController;
use App\Http\Controllers\Web\LoanController;
use App\Http\Controllers\Web\QrController;
use App\Http\Controllers\Web\ReportController;
use App\Http\Controllers\Web\UserController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Labventory Admin Web routes
|--------------------------------------------------------------------------
|
| Conventions:
|   - The web surface is for admin and laboran users only. Students use
|     the mobile app and the JSON API in routes/api.php.
|   - All `/admin/*` routes require an authenticated session and the
|     `role:admin,laboran` middleware (Requirement 4.5).
*/

Route::get('/', function (Request $request) {
    if (Auth::check() && $request->user()->isStaff()) {
        return redirect()->route('admin.dashboard');
    }

    return redirect()->route('login');
});

// Public auth routes
Route::middleware('guest')->group(function (): void {
    Route::get('/login', [LoginController::class, 'showLoginForm'])->name('login');
    Route::post('/login', [LoginController::class, 'login'])->name('login.attempt');
});

// Authenticated logout
Route::post('/logout', [LoginController::class, 'logout'])
    ->middleware('auth')
    ->name('logout');

// Admin dashboard area (Requirement 4.5)
Route::middleware(['auth', 'role:admin,laboran'])
    ->prefix('admin')
    ->name('admin.')
    ->group(function (): void {
        Route::get('/', [DashboardController::class, 'index'])->name('dashboard');

        // Category CRUD (Requirements 5.1 — 5.6)
        Route::resource('categories', CategoryController::class)
            ->except(['show']);

        // Inventory CRUD (Requirements 6.1 — 6.9, 18.3)
        Route::resource('inventories', InventoryController::class);

        // Loan workflow (Requirements 9.1 — 9.5, 10.1 — 10.8)
        Route::get('loans', [LoanController::class, 'index'])->name('loans.index');
        Route::get('loans/{loan}', [LoanController::class, 'show'])->name('loans.show');
        Route::post('loans/{loan}/approve', [LoanController::class, 'approve'])->name('loans.approve');
        Route::post('loans/{loan}/reject', [LoanController::class, 'reject'])->name('loans.reject');
        Route::post('loans/{loan}/pickup', [LoanController::class, 'pickup'])->name('loans.pickup');
        Route::post('loans/{loan}/return', [LoanController::class, 'return'])->name('loans.return');

        // Student user management (Requirements 13.1 — 13.6)
        Route::resource('users', UserController::class);

        // QR scan + code lookup (Requirements 15.6, 15.7)
        Route::get('qr/scan', [QrController::class, 'scan'])->name('qr.scan');
        Route::get('qr/lookup', [QrController::class, 'lookup'])->name('qr.lookup');

        // PDF reports (Requirements 16.1 — 16.5)
        Route::get('reports', [ReportController::class, 'index'])->name('reports.index');
        Route::get('reports/inventory/preview', [ReportController::class, 'previewInventory'])
            ->name('reports.inventory.preview');
        Route::get('reports/loans/preview', [ReportController::class, 'previewLoans'])
            ->name('reports.loans.preview');
        Route::get('reports/borrowed/preview', [ReportController::class, 'previewBorrowed'])
            ->name('reports.borrowed.preview');
        Route::get('reports/popular/preview', [ReportController::class, 'previewPopular'])
            ->name('reports.popular.preview');
        Route::get('reports/inventory.pdf', [ReportController::class, 'inventory'])
            ->name('reports.inventory');
        Route::get('reports/loans.pdf', [ReportController::class, 'loans'])
            ->name('reports.loans');
        Route::get('reports/borrowed.pdf', [ReportController::class, 'borrowed'])
            ->name('reports.borrowed');
        Route::get('reports/popular.pdf', [ReportController::class, 'popular'])
            ->name('reports.popular');
    });
