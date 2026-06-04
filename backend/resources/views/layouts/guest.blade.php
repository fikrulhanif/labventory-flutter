<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title', 'Sign in') · Labventory Admin</title>
    {{-- All assets served locally — no CDN dependency --}}
    <link href="/vendor/fonts/inter.css" rel="stylesheet">
    <link href="/vendor/bootstrap-icons/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        *, *::before, *::after { box-sizing: border-box; }
        html, body {
            margin: 0; padding: 0;
            font-family: 'Inter', system-ui, -apple-system, sans-serif;
            min-height: 100vh;
        }

        /* Animated gradient background */
        .auth-bg {
            min-height: 100vh;
            background: linear-gradient(135deg, #0f0c29 0%, #302b63 40%, #24243e 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
            position: relative;
            overflow: hidden;
        }

        /* Floating blobs */
        .auth-blob {
            position: absolute;
            border-radius: 50%;
            filter: blur(80px);
            opacity: .35;
            pointer-events: none;
        }
        .auth-blob-1 { width: 420px; height: 420px; background: #6366f1; top: -120px; left: -100px; }
        .auth-blob-2 { width: 300px; height: 300px; background: #7c3aed; bottom: -80px; right: -60px; }
        .auth-blob-3 { width: 200px; height: 200px; background: #0ea5e9; bottom: 30%; left: 55%; }

        /* Card */
        .auth-card {
            position: relative;
            z-index: 1;
            background: rgba(255,255,255,.97);
            border-radius: 24px;
            width: 100%;
            max-width: 420px;
            padding: 36px 36px 28px;
            box-shadow: 0 24px 64px rgba(0,0,0,.35), 0 0 0 1px rgba(255,255,255,.12);
        }

        /* Logo row */
        .auth-logo-row {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 24px;
        }
        .auth-logo-img {
            width: 42px; height: 42px;
            border-radius: 12px;
            object-fit: contain;
            background: #ede9fe;
            padding: 5px;
        }
        .auth-logo-name {
            font-size: 1.15rem;
            font-weight: 800;
            color: #1e1b4b;
            letter-spacing: -.02em;
        }
        .auth-logo-tag {
            font-size: .62rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: .10em;
            color: #9ca3af;
        }

        /* Headline */
        .auth-headline {
            font-size: 1.45rem;
            font-weight: 800;
            color: #111827;
            letter-spacing: -.03em;
            margin: 0 0 4px;
        }
        .auth-subline {
            font-size: .82rem;
            color: #6b7280;
            margin: 0 0 24px;
        }

        /* Fields */
        .auth-field { margin-bottom: 16px; }
        .auth-label {
            display: block;
            font-size: .74rem;
            font-weight: 700;
            color: #374151;
            margin-bottom: 6px;
            letter-spacing: .01em;
        }
        .auth-input-wrap { position: relative; }
        .auth-input-icon {
            position: absolute;
            left: 14px; top: 50%;
            transform: translateY(-50%);
            color: #9ca3af;
            font-size: .9rem;
            pointer-events: none;
        }
        .auth-input {
            width: 100%;
            padding: 11px 14px 11px 38px;
            border: 1.5px solid #e5e7eb;
            border-radius: 12px;
            font-size: .88rem;
            font-family: inherit;
            color: #111827;
            background: #fff;
            transition: border-color .15s, box-shadow .15s;
            outline: none;
        }
        .auth-input:focus {
            border-color: #6366f1;
            box-shadow: 0 0 0 3px rgba(99,102,241,.14);
        }
        .auth-input.is-invalid { border-color: #ef4444; }
        .auth-input-error { font-size: .73rem; color: #ef4444; margin-top: 4px; }

        /* Checkbox row */
        .auth-check-row {
            display: flex; align-items: center; gap: 8px;
            margin-bottom: 20px;
        }
        .auth-check-row input { accent-color: #6366f1; width: 14px; height: 14px; }
        .auth-check-row label { font-size: .78rem; color: #6b7280; cursor: pointer; }

        /* Submit */
        .auth-btn {
            width: 100%;
            padding: 13px;
            border: none;
            border-radius: 14px;
            background: linear-gradient(135deg, #6366f1 0%, #7c3aed 60%, #4f46e5 100%);
            color: #fff;
            font-size: .92rem;
            font-weight: 700;
            font-family: inherit;
            cursor: pointer;
            transition: opacity .15s, transform .1s, box-shadow .15s;
            box-shadow: 0 6px 22px rgba(99,102,241,.40);
            letter-spacing: .01em;
        }
        .auth-btn:hover   { opacity: .93; transform: translateY(-1px); box-shadow: 0 8px 28px rgba(99,102,241,.45); }
        .auth-btn:active  { transform: translateY(0); }

        /* Alerts */
        .auth-alert {
            padding: 10px 14px;
            border-radius: 12px;
            font-size: .80rem;
            display: flex; align-items: flex-start; gap: 8px;
            margin-bottom: 18px;
        }
        .auth-alert-error   { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b; }
        .auth-alert-success { background: #f0fdf4; border: 1px solid #bbf7d0; color: #166534; }

        /* Footer */
        .auth-footer {
            text-align: center;
            font-size: .73rem;
            color: #9ca3af;
            margin-top: 20px;
        }

        /* Divider under logo */
        .auth-divider {
            height: 1px;
            background: #f3f4f6;
            margin-bottom: 22px;
        }
    </style>
</head>
<body>
<div class="auth-bg">
    {{-- Decorative blobs --}}
    <div class="auth-blob auth-blob-1"></div>
    <div class="auth-blob auth-blob-2"></div>
    <div class="auth-blob auth-blob-3"></div>

    <div class="auth-card">
        {{-- Logo --}}
        <div class="auth-logo-row">
            <img src="/logo.png" alt="Labventory" class="auth-logo-img"
                 onerror="this.style.display='none'">
            <div>
                <div class="auth-logo-name">Labventory</div>
                <div class="auth-logo-tag">Admin Portal</div>
            </div>
        </div>
        <div class="auth-divider"></div>

        @yield('content')

        <p class="auth-footer">&copy; {{ now()->year }} Labventory · Campus Lab Inventory System</p>
    </div>
</div>
</body>
</html>
