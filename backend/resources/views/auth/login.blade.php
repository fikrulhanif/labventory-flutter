@extends('layouts.guest')

@section('title', 'Sign in')

@section('content')
<h2 class="auth-headline">Welcome back</h2>
<p class="auth-subline">Sign in with your admin or laboran credentials.</p>

@if (session('success'))
    <div class="auth-alert auth-alert-success">
        <i class="bi bi-check-circle-fill" style="margin-top:1px;flex-shrink:0;"></i>
        {{ session('success') }}
    </div>
@endif

@if (session('error'))
    <div class="auth-alert auth-alert-error">
        <i class="bi bi-exclamation-triangle-fill" style="margin-top:1px;flex-shrink:0;"></i>
        {{ session('error') }}
    </div>
@endif

<form method="POST" action="{{ route('login.attempt') }}" novalidate>
    @csrf

    <div class="auth-field">
        <label for="email" class="auth-label">Email address</label>
        <div class="auth-input-wrap">
            <i class="bi bi-envelope auth-input-icon"></i>
            <input type="email"
                   id="email"
                   name="email"
                   value="{{ old('email') }}"
                   class="auth-input @error('email') is-invalid @enderror"
                   autocomplete="username"
                   placeholder="admin@labventory.test"
                   required autofocus>
        </div>
        @error('email')
            <div class="auth-input-error"><i class="bi bi-x-circle me-1"></i>{{ $message }}</div>
        @enderror
    </div>

    <div class="auth-field">
        <label for="password" class="auth-label">Password</label>
        <div class="auth-input-wrap">
            <i class="bi bi-lock auth-input-icon"></i>
            <input type="password"
                   id="password"
                   name="password"
                   class="auth-input @error('password') is-invalid @enderror"
                   autocomplete="current-password"
                   placeholder="••••••••"
                   required>
        </div>
        @error('password')
            <div class="auth-input-error"><i class="bi bi-x-circle me-1"></i>{{ $message }}</div>
        @enderror
    </div>

    <div class="auth-check-row">
        <input type="checkbox" id="remember" name="remember" value="1">
        <label for="remember">Keep me signed in</label>
    </div>

    <button type="submit" class="auth-btn">
        Sign in &nbsp;<i class="bi bi-arrow-right"></i>
    </button>
</form>
@endsection
