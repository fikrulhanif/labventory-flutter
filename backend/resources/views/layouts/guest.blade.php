<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title', 'Labventory') · Labventory</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <style>
        body { background:#f8f9fc; min-height:100vh; }
        .auth-shell { min-height:100vh; display:flex; align-items:center; justify-content:center; padding:1.5rem; }
        .auth-card-wrapper { width:100%; max-width:420px; }
    </style>
</head>
<body>
    <div class="auth-shell">
        <div class="auth-card-wrapper">
            @yield('content')
            <p class="text-center text-muted small mt-4 mb-0">
                &copy; {{ now()->year }} Labventory · Campus Lab Inventory System
            </p>
        </div>
    </div>
</body>
</html>
