<?php

namespace App\Http\Controllers\Web\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/**
 * Admin Dashboard authentication.
 *
 *   GET  /login   showLoginForm
 *   POST /login   login
 *   POST /logout  logout
 *
 * Validates Requirements 4.1 — 4.4.
 *
 * Only users whose role is `admin` or `laboran` may complete the login;
 * the same form rejects students with the canonical message.
 */
class LoginController extends Controller
{
    public function showLoginForm(): View|RedirectResponse
    {
        /** @var User|null $user */
        $user = Auth::user();
        if ($user !== null && $user->isStaff()) {
            return redirect()->route('admin.dashboard');
        }

        return view('auth.login');
    }

    public function login(Request $request): RedirectResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        /** @var User|null $user */
        $user = User::query()->where('email', $credentials['email'])->first();

        if ($user === null
            || ! Auth::attempt(['email' => $credentials['email'], 'password' => $credentials['password']], (bool) $request->boolean('remember'))) {
            // Bail out of any partial attempt before re-rendering.
            Auth::guard('web')->logout();

            return back()
                ->withInput($request->only('email'))
                ->withErrors(['email' => 'Invalid email or password']);
        }

        // Requirement 4.2 — only admin/laboran roles may log into the dashboard.
        if (! $user->isStaff()) {
            Auth::guard('web')->logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return back()
                ->withInput($request->only('email'))
                ->withErrors(['email' => 'You are not authorized to access the dashboard']);
        }

        if (! $user->isActive()) {
            Auth::guard('web')->logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return back()
                ->withInput($request->only('email'))
                ->withErrors(['email' => 'Account is disabled']);
        }

        $request->session()->regenerate();

        return redirect()
            ->intended(route('admin.dashboard'))
            ->with('success', 'Welcome back, '.$user->name.'.');
    }

    public function logout(Request $request): RedirectResponse
    {
        Auth::guard('web')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('login')->with('success', 'Logged out');
    }
}
