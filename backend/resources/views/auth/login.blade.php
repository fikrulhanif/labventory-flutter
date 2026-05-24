@extends('layouts.guest')

@section('title', 'Sign in')

@section('content')
    <div class="card shadow-sm border-0">
        <div class="card-body p-4 p-md-5">
            <div class="text-center mb-4">
                <div class="d-inline-flex align-items-center justify-content-center mb-3"
                     style="width:64px;height:64px;border-radius:16px;background:#eef2ff;">
                    <i class="bi bi-box-seam" style="font-size:1.75rem;color:#4f46e5;"></i>
                </div>
                <h1 class="h4 mb-1 fw-semibold">Labventory Admin</h1>
                <p class="text-muted small mb-0">Sign in to manage inventory and loan requests.</p>
            </div>

            @if (session('success'))
                <div class="alert alert-success py-2 mb-3" role="alert">
                    {{ session('success') }}
                </div>
            @endif

            @if (session('error'))
                <div class="alert alert-danger py-2 mb-3" role="alert">
                    {{ session('error') }}
                </div>
            @endif

            <form method="POST" action="{{ route('login.attempt') }}" novalidate>
                @csrf

                <div class="mb-3">
                    <label for="email" class="form-label small fw-medium">Email</label>
                    <input type="email"
                           id="email"
                           name="email"
                           value="{{ old('email') }}"
                           class="form-control @error('email') is-invalid @enderror"
                           autocomplete="username"
                           required
                           autofocus>
                    @error('email')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>

                <div class="mb-3">
                    <label for="password" class="form-label small fw-medium">Password</label>
                    <input type="password"
                           id="password"
                           name="password"
                           class="form-control @error('password') is-invalid @enderror"
                           autocomplete="current-password"
                           required>
                    @error('password')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>

                <div class="form-check mb-3">
                    <input class="form-check-input" type="checkbox" id="remember" name="remember" value="1">
                    <label class="form-check-label small" for="remember">Remember me on this device</label>
                </div>

                <button type="submit" class="btn btn-primary w-100 fw-medium">
                    Sign in
                </button>
            </form>
        </div>
    </div>
@endsection
