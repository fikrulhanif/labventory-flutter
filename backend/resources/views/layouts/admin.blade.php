<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Dashboard') · Labventory Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <style>
        :root {
            --lv-bg: #f5f6fa;
            --lv-paper: #ffffff;
            --lv-border: #e5e7eb;
            --lv-muted: #6b7280;
            --lv-sidebar-bg: #1f2540;
            --lv-sidebar-link: rgba(255,255,255,0.72);
            --lv-sidebar-link-hover: #ffffff;
            --lv-sidebar-active-bg: rgba(255,255,255,0.08);
            --lv-primary: #4f46e5;
            --lv-radius: 12px;
        }
        body {
            background: var(--lv-bg);
            min-height: 100vh;
            font-feature-settings: "ss01", "cv11";
        }

        /* ---------- Sidebar ---------- */
        .lv-sidebar {
            position: fixed; top: 0; left: 0; bottom: 0;
            width: 240px;
            background: var(--lv-sidebar-bg);
            color: #fff;
            display: flex; flex-direction: column;
            z-index: 1020;
            box-shadow: 0 0 0 1px rgba(255,255,255,0.04) inset;
        }
        .lv-sidebar .brand {
            padding: 1.25rem 1.25rem;
            font-size: 1.05rem; font-weight: 600;
            display: flex; align-items: center; gap: .65rem;
            border-bottom: 1px solid rgba(255,255,255,0.07);
            letter-spacing: 0.01em;
        }
        .lv-sidebar .brand i {
            background: rgba(255,255,255,0.10);
            width: 36px; height: 36px;
            border-radius: 10px;
            display: inline-flex; align-items: center; justify-content: center;
        }
        .lv-sidebar nav { padding: 1rem .75rem; flex: 1; overflow-y: auto; }
        .lv-sidebar nav a {
            display: flex; align-items: center; gap: .75rem;
            padding: .55rem .85rem;
            color: var(--lv-sidebar-link);
            text-decoration: none;
            border-radius: 8px;
            font-size: .92rem;
            transition: background-color .18s ease, color .18s ease, transform .18s ease;
        }
        .lv-sidebar nav a:hover { color: var(--lv-sidebar-link-hover); background: var(--lv-sidebar-active-bg); transform: translateX(2px); }
        .lv-sidebar nav a.active {
            color: #fff;
            background: linear-gradient(90deg, rgba(79,70,229,0.30) 0%, rgba(255,255,255,0.06) 100%);
            font-weight: 500;
            box-shadow: inset 3px 0 0 var(--lv-primary);
        }
        .lv-sidebar nav a i { width: 18px; }
        .lv-sidebar nav .nav-section {
            padding: 1rem .85rem .35rem;
            text-transform: uppercase;
            font-size: .68rem;
            letter-spacing: .08em;
            color: rgba(255,255,255,0.45);
        }
        .lv-sidebar .footer {
            padding: 1rem 1.25rem;
            font-size: .78rem;
            color: rgba(255,255,255,0.55);
            border-top: 1px solid rgba(255,255,255,0.07);
        }

        /* ---------- Content ---------- */
        .lv-content { margin-left: 240px; min-height: 100vh; }
        .lv-topbar {
            background: #fff;
            border-bottom: 1px solid var(--lv-border);
            padding: .85rem 1.5rem;
            display: flex; align-items: center; justify-content: space-between;
            position: sticky; top: 0;
            z-index: 1010;
        }
        .lv-page { padding: 1.75rem; }

        /* ---------- Cards ---------- */
        .card { border-color: var(--lv-border); }
        .card .card-header.bg-white { border-bottom-color: var(--lv-border); }

        /* ---------- Tables ---------- */
        .table { --bs-table-hover-bg: #f9fafb; }
        .table > thead > tr > th {
            font-size: .76rem;
            text-transform: uppercase;
            letter-spacing: .04em;
            color: var(--lv-muted);
            font-weight: 600;
            border-bottom: 1px solid var(--lv-border);
        }
        .table > tbody > tr { transition: background-color .12s ease; }

        /* ---------- Buttons ---------- */
        .btn {
            border-radius: 10px;
            font-weight: 500;
        }
        .btn-light, .btn-outline-secondary { border-color: var(--lv-border); }

        /* ---------- Loan status pills (shared with Flutter palette) ---------- */
        .lv-pill {
            display: inline-block;
            padding: .15rem .55rem;
            border-radius: 999px;
            font-size: .72rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: .04em;
        }
        .lv-pill-pending  { background: #fef3c7; color: #92400e; }
        .lv-pill-approved { background: #cffafe; color: #155e75; }
        .lv-pill-borrowed { background: #e0e7ff; color: #3730a3; }
        .lv-pill-returned { background: #d1fae5; color: #065f46; }
        .lv-pill-rejected { background: #e5e7eb; color: #4b5563; }
        .lv-pill-available{ background: #d1fae5; color: #065f46; }
        .lv-pill-out      { background: #e5e7eb; color: #4b5563; }

        /* ---------- Forms ---------- */
        .form-control:focus, .form-select:focus {
            border-color: var(--lv-primary);
            box-shadow: 0 0 0 0.18rem rgba(79,70,229,0.18);
        }

        /* ---------- Mobile ---------- */
        @media (max-width: 768px) {
            .lv-sidebar { transform: translateX(-100%); transition: transform .22s ease; box-shadow: 4px 0 24px rgba(0,0,0,.20); }
            .lv-sidebar.open { transform: translateX(0); }
            .lv-content { margin-left: 0; }
            .lv-topbar .toggle-btn { display: inline-flex; }
        }
        .lv-topbar .toggle-btn { display: none; }

        /* Backdrop appears on mobile when sidebar is open. */
        .lv-backdrop {
            display: none;
            position: fixed; inset: 0;
            background: rgba(31,37,64,.45);
            z-index: 1019;
        }
        @media (max-width: 768px) {
            body.lv-sidebar-open .lv-backdrop { display: block; }
        }
    </style>
    @stack('head')
</head>
<body>
    <aside class="lv-sidebar" id="lv-sidebar">
        <div class="brand">
            <i class="bi bi-box-seam"></i>
            <span>Labventory</span>
        </div>

        <nav>
            <div class="nav-section">Overview</div>
            <a href="{{ route('admin.dashboard') }}"
               class="{{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">
                <i class="bi bi-speedometer2"></i> Dashboard
            </a>

            <div class="nav-section">Catalog</div>
            <a href="{{ route('admin.inventories.index') }}"
               class="{{ request()->routeIs('admin.inventories.*') ? 'active' : '' }}">
                <i class="bi bi-boxes"></i> Inventories
            </a>
            <a href="{{ route('admin.categories.index') }}"
               class="{{ request()->routeIs('admin.categories.*') ? 'active' : '' }}">
                <i class="bi bi-tags"></i> Categories
            </a>

            <div class="nav-section">Operations</div>
            <a href="{{ route('admin.loans.index') }}"
               class="{{ request()->routeIs('admin.loans.*') ? 'active' : '' }}">
                <i class="bi bi-clipboard-check"></i> Loans
            </a>
            <a href="{{ route('admin.users.index') }}"
               class="{{ request()->routeIs('admin.users.*') ? 'active' : '' }}">
                <i class="bi bi-people"></i> Users
            </a>
            <a href="{{ route('admin.reports.index') }}"
               class="{{ request()->routeIs('admin.reports.*') ? 'active' : '' }}">
                <i class="bi bi-file-earmark-pdf"></i> Reports
            </a>
            <a href="{{ route('admin.qr.scan') }}"
               class="{{ request()->routeIs('admin.qr.*') ? 'active' : '' }}">
                <i class="bi bi-qr-code-scan"></i> QR Scan
            </a>
        </nav>

        <div class="footer">
            <div>Signed in as</div>
            <div class="text-white fw-medium">{{ auth()->user()?->name }}</div>
            <div class="text-uppercase small">{{ auth()->user()?->role }}</div>
        </div>
    </aside>

    <div class="lv-content">
        <div class="lv-topbar">
            <button class="btn btn-light btn-sm toggle-btn"
                    type="button"
                    onclick="document.body.classList.toggle('lv-sidebar-open');document.getElementById('lv-sidebar').classList.toggle('open')">
                <i class="bi bi-list"></i>
            </button>

            <div class="ms-auto d-flex align-items-center gap-3">
                <span class="text-muted small d-none d-md-inline">{{ auth()->user()?->email }}</span>
                <form method="POST" action="{{ route('logout') }}" class="m-0">
                    @csrf
                    <button type="submit" class="btn btn-outline-secondary btn-sm">
                        <i class="bi bi-box-arrow-right me-1"></i> Logout
                    </button>
                </form>
            </div>
        </div>

        <main class="lv-page">
            @if (session('success'))
                <div class="alert alert-success alert-dismissible fade show" role="alert">
                    {{ session('success') }}
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            @endif

            @if (session('error'))
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    {{ session('error') }}
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            @endif

            @yield('content')
        </main>
    </div>

    {{-- Backdrop appears on mobile when sidebar is open; clicking it closes the sidebar. --}}
    <div class="lv-backdrop"></div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Close mobile sidebar when the backdrop or any nav link is clicked.
        (function () {
            const backdrop = document.querySelector('.lv-backdrop');
            const sidebar  = document.getElementById('lv-sidebar');
            const close = function () {
                document.body.classList.remove('lv-sidebar-open');
                sidebar.classList.remove('open');
            };
            backdrop?.addEventListener('click', close);
            sidebar.querySelectorAll('nav a').forEach(function (a) {
                a.addEventListener('click', function () {
                    if (window.matchMedia('(max-width: 768px)').matches) close();
                });
            });
        })();
    </script>
    @stack('scripts')
</body>
</html>
