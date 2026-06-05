<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Dasbor') · Labventory Admin</title>
    {{-- All assets served locally — no CDN dependency --}}
    <link href="/vendor/bootstrap/bootstrap.min.css" rel="stylesheet">
    <link href="/vendor/bootstrap-icons/bootstrap-icons.min.css" rel="stylesheet">
    <link href="/vendor/fonts/inter.css" rel="stylesheet">
    <style>        /* ── Design tokens ────────────────────────────────────────── */
        :root {
            --lv-sidebar-w: 248px;
            --lv-topbar-h: 58px;

            /* Sidebar */
            --lv-sidebar-bg: #0f1623;
            --lv-sidebar-border: rgba(255,255,255,0.06);
            --lv-sidebar-link: rgba(255,255,255,0.60);
            --lv-sidebar-link-hover: rgba(255,255,255,0.90);
            --lv-sidebar-active-bg: rgba(99,102,241,0.18);
            --lv-sidebar-active-text: #c7d2fe;
            --lv-sidebar-active-bar: #6366f1;
            --lv-sidebar-section: rgba(255,255,255,0.30);

            /* Page */
            --lv-bg: #e8ecf5;
            --lv-surface: #ffffff;
            --lv-border: #d4d8e8;
            --lv-surface-alt: #f5f7ff;  /* slightly off-white for zebra/header */

            /* Brand */
            --lv-primary: #6366f1;
            --lv-primary-dark: #4f46e5;

            /* Stat card gradient pairs */
            --lv-stat-1s: #6366f1; --lv-stat-1e: #8b5cf6;
            --lv-stat-2s: #0ea5e9; --lv-stat-2e: #06b6d4;
            --lv-stat-3s: #10b981; --lv-stat-3e: #34d399;
            --lv-stat-4s: #f59e0b; --lv-stat-4e: #fbbf24;
            --lv-stat-5s: #ef4444; --lv-stat-5e: #f97316;
        }

        /* ── Global ───────────────────────────────────────────────── */
        *, *::before, *::after { box-sizing: border-box; }

        body {
            font-family: 'Inter', system-ui, -apple-system, sans-serif;
            background: var(--lv-bg);
            color: #1e2334;
            min-height: 100vh;
            margin: 0;
        }

        /* ── Sidebar ──────────────────────────────────────────────── */
        .lv-sidebar {
            position: fixed;
            top: 0; left: 0;
            width: var(--lv-sidebar-w);
            height: 100vh;
            background: var(--lv-sidebar-bg);
            display: flex;
            flex-direction: column;
            z-index: 1000;
            overflow: hidden;           /* NO scrollbar ever */
            border-right: 1px solid var(--lv-sidebar-border);
        }

        /* Brand row */
        .lv-brand {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 18px 20px 16px;
            text-decoration: none;
            border-bottom: 1px solid var(--lv-sidebar-border);
            flex-shrink: 0;
        }
        .lv-brand-logo {
            width: 36px; height: 36px;
            border-radius: 10px;
            overflow: hidden;
            background: rgba(255,255,255,0.08);
            display: flex; align-items: center; justify-content: center;
            flex-shrink: 0;
        }
        .lv-brand-logo img { width: 26px; height: 26px; object-fit: contain; }
        .lv-brand-name {
            color: #fff;
            font-size: .95rem;
            font-weight: 700;
            letter-spacing: -.01em;
            line-height: 1;
        }
        .lv-brand-tag {
            color: rgba(255,255,255,.40);
            font-size: .65rem;
            font-weight: 500;
            letter-spacing: .08em;
            text-transform: uppercase;
        }

        /* Nav */
        .lv-nav {
            flex: 1;
            overflow: hidden;          /* clips any accidental overflow  */
            padding: 10px 12px;
            display: flex;
            flex-direction: column;
            gap: 2px;
        }
        .lv-nav-section {
            font-size: .60rem;
            font-weight: 700;
            letter-spacing: .10em;
            text-transform: uppercase;
            color: var(--lv-sidebar-section);
            padding: 14px 8px 4px;
        }
        .lv-nav a {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 8px 12px;
            color: var(--lv-sidebar-link);
            text-decoration: none;
            border-radius: 10px;
            font-size: .84rem;
            font-weight: 500;
            transition: background .15s, color .15s, transform .15s;
            white-space: nowrap;
            overflow: hidden;
        }
        .lv-nav a i { font-size: .95rem; width: 18px; flex-shrink: 0; }
        .lv-nav a span { overflow: hidden; text-overflow: ellipsis; }
        .lv-nav a:hover {
            background: rgba(255,255,255,.06);
            color: var(--lv-sidebar-link-hover);
            transform: translateX(2px);
        }
        .lv-nav a.active {
            background: var(--lv-sidebar-active-bg);
            color: var(--lv-sidebar-active-text);
            font-weight: 600;
            box-shadow: inset 3px 0 0 var(--lv-sidebar-active-bar);
        }

        /* Footer */
        .lv-sidebar-footer {
            padding: 12px 16px;
            border-top: 1px solid var(--lv-sidebar-border);
            flex-shrink: 0;
        }
        .lv-user-row {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .lv-avatar {
            width: 32px; height: 32px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--lv-primary), #8b5cf6);
            display: flex; align-items: center; justify-content: center;
            color: #fff;
            font-size: .7rem;
            font-weight: 700;
            flex-shrink: 0;
        }
        .lv-user-name { color: #fff; font-size: .8rem; font-weight: 600; }
        .lv-user-role { color: rgba(255,255,255,.40); font-size: .62rem; text-transform: uppercase; letter-spacing: .06em; }

        /* ── Content shell ────────────────────────────────────────── */
        .lv-shell {
            margin-left: var(--lv-sidebar-w);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        /* ── Topbar ───────────────────────────────────────────────── */
        .lv-topbar {
            position: sticky;
            top: 0;
            z-index: 900;
            height: var(--lv-topbar-h);
            background: var(--lv-surface);
            border-bottom: 2px solid #c8cedd;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 24px;
            gap: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,.06);
        }
        .lv-page-title {
            font-size: .9rem;
            font-weight: 700;
            color: #1e2334;
        }
        .lv-topbar-right {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .lv-email-badge {
            background: #f1f3f9;
            border: 1px solid var(--lv-border);
            border-radius: 999px;
            padding: 4px 12px;
            font-size: .75rem;
            color: #6b7280;
            display: none;
        }
        @media(min-width:900px){ .lv-email-badge { display: block; } }

        .btn-logout {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 6px 14px;
            border: 1px solid #e5e7eb;
            border-radius: 10px;
            background: #fff;
            color: #6b7280;
            font-size: .78rem;
            font-weight: 600;
            cursor: pointer;
            transition: background .15s, color .15s, border-color .15s;
            text-decoration: none;
        }
        .btn-logout:hover {
            background: #fee2e2;
            border-color: #fca5a5;
            color: #dc2626;
        }

        /* Mobile sidebar toggle */
        .lv-menu-toggle {
            display: none;
            background: none;
            border: none;
            font-size: 1.3rem;
            color: #6b7280;
            cursor: pointer;
            padding: 4px;
        }
        @media(max-width:767px) {
            .lv-menu-toggle { display: block; }
            .lv-sidebar { transform: translateX(-100%); transition: transform .22s ease; }
            .lv-sidebar.open { transform: translateX(0); }
            .lv-shell { margin-left: 0; }
        }
        .lv-backdrop {
            display: none;
            position: fixed; inset: 0;
            background: rgba(0,0,0,.35);
            z-index: 999;
        }
        @media(max-width:767px) {
            body.sidebar-open .lv-backdrop { display: block; }
        }

        /* ── Page ─────────────────────────────────────────────────── */
        .lv-page { padding: 24px; flex: 1; }

        /* ── Flash alerts ─────────────────────────────────────────── */
        .lv-flash {
            padding: 10px 16px;
            border-radius: 12px;
            font-size: .85rem;
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 18px;
            border: 1px solid transparent;
        }
        .lv-flash-success { background: #f0fdf4; border-color: #bbf7d0; color: #166534; }
        .lv-flash-error   { background: #fef2f2; border-color: #fecaca; color: #991b1b; }

        /* ── Stat cards ───────────────────────────────────────────── */
        .lv-stat {
            border-radius: 18px;
            padding: 18px 20px;
            color: #fff;
            position: relative;
            overflow: hidden;
            display: flex;
            align-items: flex-start;
            gap: 14px;
            box-shadow: 0 4px 24px rgba(0,0,0,0.10);
        }
        .lv-stat::after {
            content: '';
            position: absolute;
            right: -20px; top: -20px;
            width: 100px; height: 100px;
            border-radius: 50%;
            background: rgba(255,255,255,.10);
        }
        .lv-stat-icon {
            width: 46px; height: 46px;
            border-radius: 14px;
            background: rgba(255,255,255,.18);
            display: flex; align-items: center; justify-content: center;
            font-size: 1.3rem;
            flex-shrink: 0;
        }
        .lv-stat-label {
            font-size: .70rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: .07em;
            opacity: .80;
        }
        .lv-stat-value {
            font-size: 2rem;
            font-weight: 800;
            line-height: 1;
            letter-spacing: -.03em;
        }
        .lv-stat-1 { background: linear-gradient(135deg, var(--lv-stat-1s), var(--lv-stat-1e)); }
        .lv-stat-2 { background: linear-gradient(135deg, var(--lv-stat-2s), var(--lv-stat-2e)); }
        .lv-stat-3 { background: linear-gradient(135deg, var(--lv-stat-3s), var(--lv-stat-3e)); }
        .lv-stat-4 { background: linear-gradient(135deg, var(--lv-stat-4s), var(--lv-stat-4e)); }
        .lv-stat-5 { background: linear-gradient(135deg, var(--lv-stat-5s), var(--lv-stat-5e)); }

        /* ── Cards ────────────────────────────────────────────────── */
        .lv-card {
            background: var(--lv-surface);
            border-radius: 16px;
            border: 1.5px solid #c8cedd;
            overflow: hidden;
            box-shadow: 0 2px 12px rgba(0,0,0,.06), 0 0 0 0.5px rgba(0,0,0,.04);
        }
        .lv-card-header {
            padding: 14px 20px;
            border-bottom: 1.5px solid #d8dcea;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 10px;
            /* Tinted header makes the card structure immediately obvious */
            background: #f5f7ff;
        }
        .lv-card-title {
            font-size: .88rem;
            font-weight: 700;
            color: #1e2334;
        }

        /* ── Tables ───────────────────────────────────────────────── */
        .lv-table {
            width: 100%;
            border-collapse: collapse;
        }
        .lv-table thead th {
            /* Solid colored header — immediately visible as distinct from body */
            background: #e8ecfa;
            color: #3b4268;
            font-size: .68rem;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: .08em;
            padding: 11px 14px;
            border-bottom: 2px solid #c8cedd;
            white-space: nowrap;
        }
        .lv-table thead th:first-child { padding-left: 20px; }
        .lv-table thead th:last-child  { padding-right: 20px; }
        .lv-table tbody tr {
            border-bottom: 1px solid #ebedf8;
            transition: background .10s;
        }
        /* Zebra striping — even rows get a very subtle tint */
        .lv-table tbody tr:nth-child(even) { background: #f7f8ff; }
        .lv-table tbody tr:last-child { border-bottom: none; }
        .lv-table tbody tr:hover { background: #eef1ff !important; }
        .lv-table tbody td {
            padding: 13px 14px;
            font-size: .83rem;
            color: #374151;
            vertical-align: middle;
        }
        .lv-table tbody td:first-child { padding-left: 20px; }
        .lv-table tbody td:last-child  { padding-right: 20px; }

        /* ── Buttons ──────────────────────────────────────────────── */
        .btn { border-radius: 10px; font-weight: 600; font-size: .82rem; }
        .btn-primary   { background: var(--lv-primary); border-color: var(--lv-primary); }
        .btn-primary:hover { background: var(--lv-primary-dark); border-color: var(--lv-primary-dark); }
        .btn-outline-primary { border-color: var(--lv-primary); color: var(--lv-primary); }
        .btn-outline-primary:hover { background: var(--lv-primary); color: #fff; }
        .btn-sm { font-size: .75rem; padding: 5px 11px; border-radius: 8px; }

        /* Ghost secondary button — visible even on white */
        .btn-ghost {
            background: #f1f3f9;
            border: 1px solid var(--lv-border);
            color: #374151;
        }
        .btn-ghost:hover { background: #e8eaf0; color: #111; }

        /* Apply/filter button */
        .btn-apply {
            background: #1e2334;
            border: 1px solid #1e2334;
            color: #fff;
        }
        .btn-apply:hover { background: #111827; color: #fff; }

        /* ── Forms ────────────────────────────────────────────────── */
        .form-control, .form-select {
            border-radius: 10px;
            border-color: #d1d5db;
            font-size: .83rem;
            transition: border-color .15s, box-shadow .15s;
        }
        .form-control:focus, .form-select:focus {
            border-color: var(--lv-primary);
            box-shadow: 0 0 0 3px rgba(99,102,241,.12);
        }
        .form-label { font-size: .78rem; font-weight: 600; color: #374151; }

        /* ── Filter row ───────────────────────────────────────────── */
        .lv-filters {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            align-items: flex-end;
        }
        .lv-filter-field { display: flex; flex-direction: column; gap: 4px; }
        .lv-filter-field input,
        .lv-filter-field select { min-width: 160px; max-width: 240px; }

        /* ── Status pills — more vibrant for readability ─────────── */
        .lv-pill {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 4px 11px;
            border-radius: 999px;
            font-size: .70rem;
            font-weight: 800;
            letter-spacing: .04em;
            text-transform: uppercase;
        }
        .lv-pill::before {
            content: '';
            width: 5px; height: 5px;
            border-radius: 50%;
            background: currentColor;
        }
        /* Higher opacity backgrounds + darker text for contrast */
        .lv-pill-pending  { background:#fef3c7; color:#b45309; border:1.5px solid #fcd34d; }
        .lv-pill-approved { background:#cffafe; color:#0e7490; border:1.5px solid #67e8f9; }
        .lv-pill-borrowed { background:#ede9fe; color:#6d28d9; border:1.5px solid #a78bfa; }
        .lv-pill-returned { background:#d1fae5; color:#065f46; border:1.5px solid #6ee7b7; }
        .lv-pill-rejected { background:#f3f4f6; color:#374151; border:1.5px solid #9ca3af; }
        .lv-pill-available{ background:#d1fae5; color:#065f46; border:1.5px solid #6ee7b7; }
        .lv-pill-out      { background:#fee2e2; color:#991b1b; border:1.5px solid #fca5a5; }
        .lv-pill-active   { background:#dbeafe; color:#1d4ed8; border:1.5px solid #93c5fd; }
        .lv-pill-inactive { background:#f3f4f6; color:#374151; border:1.5px solid #9ca3af; }

        /* ── Pagination ───────────────────────────────────────────── */
        .pagination {
            margin: 0;
            gap: 4px;
        }
        .page-link {
            border-radius: 8px;
            font-size: .78rem;
            font-weight: 600;
            color: #374151;
            border-color: var(--lv-border);
        }
        .page-item.active .page-link {
            background: var(--lv-primary);
            border-color: var(--lv-primary);
        }

        /* ── Code tags ────────────────────────────────────────────── */
        code {
            font-size: .78rem;
            padding: 2px 7px;
            background: #f1f3f9;
            border-radius: 6px;
            color: var(--lv-primary);
            border: 1px solid var(--lv-border);
        }

        /* ── Breadcrumb ───────────────────────────────────────────── */
        .breadcrumb { font-size: .75rem; }
        .breadcrumb-item a { color: var(--lv-primary); text-decoration: none; }

        /* ── Page header row ──────────────────────────────────────── */
        .lv-page-header {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            margin-bottom: 20px;
        }
        .lv-page-header h1 {
            font-size: 1.18rem;
            font-weight: 800;
            color: #111827;
            margin: 0 0 2px;
            letter-spacing: -.02em;
        }
        .lv-page-header p {
            font-size: .80rem;
            color: #6b7280;
            margin: 0;
        }

        /* ── Empty state ──────────────────────────────────────────── */
        .lv-empty {
            text-align: center;
            padding: 48px 24px;
            color: #9ca3af;
        }
        .lv-empty i { font-size: 2.5rem; opacity: .5; display: block; margin-bottom: 10px; }
        .lv-empty p { font-size: .85rem; margin: 0; }

        /* ── Action buttons in table ──────────────────────────────── */
        .lv-actions { display: flex; gap: 5px; justify-content: flex-end; }
        .lv-actions .btn { padding: 5px 10px; }

        /* Colored icon action buttons — visible on white/light backgrounds */
        .lv-btn-view {
            display: inline-flex; align-items: center; justify-content: center;
            width: 32px; height: 32px; border-radius: 8px;
            background: #eff6ff; border: 1.5px solid #bfdbfe; color: #1d4ed8;
            cursor: pointer; transition: background .14s, color .14s, transform .10s;
            text-decoration: none;
        }
        .lv-btn-view:hover { background: #1d4ed8; color: #fff; transform: scale(1.05); }

        .lv-btn-edit {
            display: inline-flex; align-items: center; justify-content: center;
            width: 32px; height: 32px; border-radius: 8px;
            background: #fefce8; border: 1.5px solid #fde047; color: #a16207;
            cursor: pointer; transition: background .14s, color .14s, transform .10s;
            text-decoration: none;
        }
        .lv-btn-edit:hover { background: #ca8a04; color: #fff; transform: scale(1.05); }

        .lv-btn-delete {
            display: inline-flex; align-items: center; justify-content: center;
            width: 32px; height: 32px; border-radius: 8px;
            background: #fef2f2; border: 1.5px solid #fca5a5; color: #dc2626;
            cursor: pointer; transition: background .14s, color .14s, transform .10s;
        }
        .lv-btn-delete:hover { background: #dc2626; color: #fff; transform: scale(1.05); }

        /* Image thumbnails — consistent border treatment */
        .lv-thumb {
            width: 42px; height: 42px;
            border-radius: 10px;
            object-fit: cover;
            border: 2px solid #c8cedd;
            background: #f0f3ff;
            flex-shrink: 0;
        }
        .lv-thumb-placeholder {
            width: 42px; height: 42px;
            border-radius: 10px;
            border: 2px solid #c8cedd;
            background: #eef1ff;
            display: flex; align-items: center; justify-content: center;
            flex-shrink: 0;
        }
        .lv-thumb-placeholder i { font-size: .9rem; color: #a5b4fc; }
    </style>
    @stack('head')
</head>
<body>

{{-- Sidebar --}}
<aside class="lv-sidebar" id="lv-sidebar">
    {{-- Brand --}}
    <a href="{{ route('admin.dashboard') }}" class="lv-brand">
        <div class="lv-brand-logo">
            <img src="/logo.png" alt="Labventory logo"
                 onerror="this.style.display='none';this.nextElementSibling.style.display='flex'"
                 style="">
            <div style="display:none;width:26px;height:26px;align-items:center;justify-content:center;color:#818cf8;font-size:1rem;">
                <i class="bi bi-box-seam"></i>
            </div>
        </div>
        <div>
            <div class="lv-brand-name">Labventory</div>
            <div class="lv-brand-tag">Portal Admin</div>
        </div>
    </a>

    {{-- Navigation --}}
    <nav class="lv-nav">
        <div class="lv-nav-section">Overview</div>
        <a href="{{ route('admin.dashboard') }}"
           class="{{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">
            <i class="bi bi-grid-1x2-fill"></i><span>Dashboard</span>
        </a>

        <div class="lv-nav-section">Katalog</div>
        <a href="{{ route('admin.inventories.index') }}"
           class="{{ request()->routeIs('admin.inventories.*') ? 'active' : '' }}">
            <i class="bi bi-boxes"></i><span>Inventaris</span>
        </a>
        <a href="{{ route('admin.categories.index') }}"
           class="{{ request()->routeIs('admin.categories.*') ? 'active' : '' }}">
            <i class="bi bi-tags-fill"></i><span>Kategori</span>
        </a>

        <div class="lv-nav-section">Operasi</div>
        <a href="{{ route('admin.loans.index') }}"
           class="{{ request()->routeIs('admin.loans.*') ? 'active' : '' }}">
            <i class="bi bi-clipboard2-check-fill"></i><span>Peminjaman</span>
        </a>
        <a href="{{ route('admin.users.index') }}"
           class="{{ request()->routeIs('admin.users.*') ? 'active' : '' }}">
            <i class="bi bi-people-fill"></i><span>Mahasiswa</span>
        </a>
        <a href="{{ route('admin.staff-users.index') }}"
           class="{{ request()->routeIs('admin.staff-users.*') ? 'active' : '' }}">
            <i class="bi bi-person-gear"></i><span>Staf</span>
        </a>
        <a href="{{ route('admin.reports.index') }}"
           class="{{ request()->routeIs('admin.reports.*') ? 'active' : '' }}">
            <i class="bi bi-file-earmark-bar-graph-fill"></i><span>Laporan</span>
        </a>
        <a href="{{ route('admin.qr.scan') }}"
           class="{{ request()->routeIs('admin.qr.*') ? 'active' : '' }}">
            <i class="bi bi-qr-code-scan"></i><span>Scan QR</span>
        </a>
    </nav>

    {{-- Footer --}}
    <div class="lv-sidebar-footer">
        <div class="lv-user-row">
            <div class="lv-avatar">
                {{ strtoupper(substr(auth()->user()?->name ?? 'A', 0, 1)) }}
            </div>
            <div style="overflow:hidden;flex:1;">
                <div class="lv-user-name" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
                    {{ auth()->user()?->name ?? '' }}
                </div>
                <div class="lv-user-role">{{ auth()->user()?->role ?? '' }}</div>
            </div>
        </div>
    </div>
</aside>

{{-- Backdrop (mobile) --}}
<div class="lv-backdrop" id="lv-backdrop"></div>

{{-- Main shell --}}
<div class="lv-shell">

    {{-- Topbar --}}
    <div class="lv-topbar">
        <div style="display:flex;align-items:center;gap:12px;">
            <button class="lv-menu-toggle" id="lv-menu-btn" type="button" aria-label="Toggle sidebar">
                <i class="bi bi-list"></i>
            </button>
            <span class="lv-page-title">@yield('title', 'Dasbor')</span>
        </div>
        <div class="lv-topbar-right">
            <span class="lv-email-badge">{{ auth()->user()?->email }}</span>
            <form method="POST" action="{{ route('logout') }}" class="m-0" data-logout>
                @csrf
                <button type="submit" class="btn-logout">
                    <i class="bi bi-box-arrow-right"></i> Keluar
                </button>
            </form>
        </div>
    </div>

    {{-- Content --}}
    <main class="lv-page">
        @if (session('success'))
            <div class="lv-flash lv-flash-success">
                <i class="bi bi-check-circle-fill"></i>
                {{ session('success') }}
            </div>
        @endif
        @if (session('error'))
            <div class="lv-flash lv-flash-error">
                <i class="bi bi-exclamation-triangle-fill"></i>
                {{ session('error') }}
            </div>
        @endif

        @yield('content')
    </main>
</div>

<script src="/vendor/bootstrap/bootstrap.bundle.min.js"></script>
{{-- SweetAlert2 served locally from public/vendor --}}
<script src="/vendor/sweetalert2/sweetalert2.all.min.js"></script>
<script>
/* ── Sidebar mobile toggle ─────────────────────────────────────── */
(function () {
    const btn     = document.getElementById('lv-menu-btn');
    const sidebar = document.getElementById('lv-sidebar');
    const backdrop = document.getElementById('lv-backdrop');

    function openSidebar()  { sidebar.classList.add('open'); document.body.classList.add('sidebar-open'); }
    function closeSidebar() { sidebar.classList.remove('open'); document.body.classList.remove('sidebar-open'); }

    btn?.addEventListener('click', function () {
        sidebar.classList.contains('open') ? closeSidebar() : openSidebar();
    });
    backdrop?.addEventListener('click', closeSidebar);
    sidebar.querySelectorAll('.lv-nav a').forEach(function (a) {
        a.addEventListener('click', function () {
            if (window.matchMedia('(max-width:767px)').matches) closeSidebar();
        });
    });
})();
/* ── SweetAlert2 default theme matching our design system ─────── */
const SwalBase = Swal.mixin({
    customClass: {
        popup: 'lv-swal-popup',
        confirmButton: 'lv-swal-confirm',
        cancelButton: 'lv-swal-cancel',
    },
    buttonsStyling: false,
    reverseButtons: true,
    showCancelButton: true,
    allowOutsideClick: true,
    backdrop: 'rgba(15,22,35,0.55)',
    padding: '24px',
    didOpen: function () {
        document.querySelector('.swal2-popup')?.style.setProperty('font-family', "'Inter', system-ui, sans-serif");
    },
});

/* ── Global delete/action confirm ──────────────────────────────── */
/**
 * Call lvConfirm() in a data attribute or inline to replace
 * onsubmit="return confirm(...)".
 *
 * Usage (in blade):
 *   <form data-confirm="Delete this item?">
 *   ... or use the lvConfirmDelete helper below
 */
document.addEventListener('DOMContentLoaded', function () {

    // ── Form confirm via data-confirm attribute ──────────────────
    document.querySelectorAll('form[data-confirm]').forEach(function (form) {
        form.addEventListener('submit', async function (e) {
            e.preventDefault();
            const msg  = form.dataset.confirm || 'Are you sure?';
            const tone = form.dataset.confirmTone || 'warning';  // warning | danger | info
            const icons = { warning: 'warning', danger: 'error', info: 'question' };
            const result = await SwalBase.fire({
                icon: icons[tone] || 'warning',
                title: form.dataset.confirmTitle || 'Konfirmasi tindakan',
                text:  msg,
                confirmButtonText: form.dataset.confirmYes  || 'Ya, lanjutkan',
                cancelButtonText:  form.dataset.confirmNo   || 'Batal',
            });
            if (result.isConfirmed) form.submit();
        });
    });

    // ── Logout button ────────────────────────────────────────────
    const logoutForms = document.querySelectorAll('form[data-logout]');
    logoutForms.forEach(function (form) {
        form.addEventListener('submit', async function (e) {
            e.preventDefault();
            const result = await SwalBase.fire({
                icon: 'question',
                title: 'Keluar?',
                text: 'Anda akan diarahkan ke halaman login.',
                confirmButtonText: 'Ya, keluar',
                cancelButtonText: 'Tetap masuk',
            });
            if (result.isConfirmed) form.submit();
        });
    });
});
</script>
<style>
/* SweetAlert2 overrides to match our design */
.lv-swal-popup {
    border-radius: 20px !important;
    border: 1px solid #e8eaf0 !important;
    box-shadow: 0 24px 64px rgba(0,0,0,.14) !important;
}
.lv-swal-confirm, .lv-swal-cancel {
    padding: 9px 22px;
    border-radius: 10px;
    font-size: .84rem;
    font-weight: 700;
    font-family: 'Inter', system-ui, sans-serif;
    cursor: pointer;
    border: none;
    transition: opacity .15s;
}
.lv-swal-confirm {
    background: #6366f1;
    color: #fff;
    margin-left: 8px;
}
.lv-swal-confirm:hover { opacity: .88; }
.lv-swal-cancel {
    background: #f1f3f9;
    color: #374151;
    border: 1px solid #e5e7eb;
}
.lv-swal-cancel:hover { background: #e8eaf0; }
.swal2-title   { font-family: 'Inter', system-ui, sans-serif !important; font-size: 1.1rem !important; color: #111827 !important; }
.swal2-html-container { font-family: 'Inter', system-ui, sans-serif !important; font-size: .85rem !important; color: #6b7280 !important; }
</style>
@stack('scripts')
</body>
</html>
