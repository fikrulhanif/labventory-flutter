<?php

use App\Http\Controllers\Web\Auth\LoginController;
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
        Route::view('/', 'dashboard.index')->name('dashboard');
    });
