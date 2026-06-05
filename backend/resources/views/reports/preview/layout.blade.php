<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title') · Labventory Report</title>
    {{-- All assets served locally — no CDN dependency --}}
    <link href="/vendor/bootstrap/bootstrap.min.css" rel="stylesheet">
    <link href="/vendor/bootstrap-icons/bootstrap-icons.min.css" rel="stylesheet">
    <link href="/vendor/fonts/inter.css" rel="stylesheet">
    <style>
        :root {
            --lv-bg: #e8ecf5;
            --lv-paper: #ffffff;
            --lv-border: #d4d8e8;
            --lv-primary: #6366f1;
            --lv-header-bg: #f0f3ff;
        }
        *, *::before, *::after { box-sizing: border-box; }
        body {
            background: var(--lv-bg);
            color: #1e2334;
            font-family: 'Inter', 'Segoe UI', system-ui, -apple-system, sans-serif;
            margin: 0;
        }

        /* ── Sticky toolbar ──────────────────────────────────────── */
        .lv-toolbar {
            position: sticky;
            top: 0;
            z-index: 100;
            background: linear-gradient(135deg, #1e2334 0%, #2d3748 100%);
            border-bottom: 2px solid #4a5568;
            padding: 12px 24px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 10px;
            box-shadow: 0 2px 12px rgba(0,0,0,.20);
        }
        .lv-toolbar-left h1 {
            font-size: .95rem;
            font-weight: 700;
            color: #fff;
            margin: 0 0 2px;
            letter-spacing: -.01em;
        }
        .lv-toolbar-left .meta {
            font-size: .72rem;
            color: rgba(255,255,255,.60);
        }
        .lv-toolbar-actions {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }
        .toolbar-btn {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 7px 16px;
            border-radius: 10px;
            font-size: .78rem;
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
            border: 1.5px solid transparent;
            transition: all .14s;
        }
        .toolbar-btn-back {
            background: rgba(255,255,255,.10);
            border-color: rgba(255,255,255,.20);
            color: rgba(255,255,255,.85);
        }
        .toolbar-btn-back:hover { background: rgba(255,255,255,.20); color: #fff; }
        .toolbar-btn-print {
            background: rgba(255,255,255,.12);
            border-color: rgba(255,255,255,.22);
            color: #fff;
        }
        .toolbar-btn-print:hover { background: rgba(255,255,255,.22); }
        .toolbar-btn-download {
            background: #6366f1;
            border-color: #4f46e5;
            color: #fff;
            box-shadow: 0 2px 10px rgba(99,102,241,.35);
        }
        .toolbar-btn-download:hover { background: #4f46e5; transform: translateY(-1px); }

        /* ── Paper container ─────────────────────────────────────── */
        .lv-paper {
            max-width: 1120px;
            margin: 24px auto;
            padding: 32px 36px;
            background: var(--lv-paper);
            border: 1.5px solid var(--lv-border);
            border-radius: 16px;
            box-shadow: 0 4px 20px rgba(0,0,0,.07);
        }

        /* ── Report header ───────────────────────────────────────── */
        .report-header {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 12px;
            padding-bottom: 20px;
            border-bottom: 2px solid #e8ecfa;
            margin-bottom: 24px;
        }
        .report-header-left {}
        .report-logo-row {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 8px;
        }
        .report-logo-row img {
            width: 34px; height: 34px;
            object-fit: contain;
            border-radius: 8px;
            background: #eef2ff;
            padding: 3px;
        }
        .report-brand { font-size: .78rem; font-weight: 700; color: #6366f1; text-transform: uppercase; letter-spacing: .07em; }
        .report-title {
            font-size: 1.6rem;
            font-weight: 800;
            color: #111827;
            letter-spacing: -.03em;
            margin: 0 0 4px;
        }
        .report-subtitle { font-size: .82rem; color: #6b7280; margin: 0; }

        .report-header-right {
            text-align: right;
        }
        .report-generated { font-size: .72rem; color: #9ca3af; margin-bottom: 6px; }

        /* ── Meta info grid ──────────────────────────────────────── */
        .report-meta {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            margin-bottom: 24px;
        }
        .meta-chip {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 10px 16px;
            background: var(--lv-header-bg);
            border: 1.5px solid #c8d0e8;
            border-radius: 12px;
            min-width: 120px;
        }
        .meta-chip-icon {
            width: 32px; height: 32px;
            border-radius: 8px;
            background: var(--lv-primary);
            display: flex; align-items: center; justify-content: center;
            color: #fff;
            font-size: .85rem;
            flex-shrink: 0;
        }
        .meta-chip-label { font-size: .65rem; text-transform: uppercase; letter-spacing: .07em; color: #9ca3af; font-weight: 700; }
        .meta-chip-value { font-size: 1.1rem; font-weight: 800; color: #111827; letter-spacing: -.02em; }

        /* ── Section title ───────────────────────────────────────── */
        .section-title {
            font-size: .72rem;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: .09em;
            color: #6b7280;
            margin: 0 0 10px;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .section-title::after {
            content: '';
            flex: 1;
            height: 1.5px;
            background: #e8ecfa;
        }

        /* ── Tables ──────────────────────────────────────────────── */
        table.report-table { width: 100%; border-collapse: collapse; font-size: .84rem; }
        table.report-table thead th {
            background: #e8ecfa;
            color: #3b4268;
            font-size: .68rem;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: .08em;
            padding: 10px 14px;
            border-bottom: 2px solid #c8cedd;
            white-space: nowrap;
        }
        table.report-table thead th:first-child { padding-left: 18px; }
        table.report-table thead th:last-child  { padding-right: 18px; }
        table.report-table tbody tr { border-bottom: 1px solid #ebedf8; transition: background .10s; }
        table.report-table tbody tr:nth-child(even) { background: #f7f8ff; }
        table.report-table tbody tr:hover { background: #eef1ff; }
        table.report-table tbody td { padding: 11px 14px; vertical-align: middle; color: #374151; }
        table.report-table tbody td:first-child { padding-left: 18px; }
        table.report-table tbody td:last-child  { padding-right: 18px; }
        table.report-table td.num { text-align: right; font-weight: 700; }
        table.report-table td.muted { color: #9ca3af; font-size: .78rem; }
        table.report-table code { font-size: .75rem; padding: 2px 6px; background: #eef1ff; border-radius: 5px; color: #6366f1; border: 1px solid #c7d2fe; }

        /* ── Pills ───────────────────────────────────────────────── */
        .pill {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 3px 10px;
            border-radius: 999px;
            font-size: .68rem;
            font-weight: 800;
            letter-spacing: .04em;
            text-transform: uppercase;
        }
        .pill::before { content: ''; width: 5px; height: 5px; border-radius: 50%; background: currentColor; }
        .pill-pending  { background:#fef3c7; color:#b45309; border:1.5px solid #fcd34d; }
        .pill-approved { background:#cffafe; color:#0e7490; border:1.5px solid #67e8f9; }
        .pill-borrowed { background:#ede9fe; color:#6d28d9; border:1.5px solid #a78bfa; }
        .pill-returned { background:#d1fae5; color:#065f46; border:1.5px solid #6ee7b7; }
        .pill-rejected { background:#f3f4f6; color:#374151; border:1.5px solid #9ca3af; }
        .pill-available{ background:#d1fae5; color:#065f46; border:1.5px solid #6ee7b7; }
        .pill-out      { background:#fee2e2; color:#991b1b; border:1.5px solid #fca5a5; }

        /* ── Empty state ─────────────────────────────────────────── */
        .empty-state {
            text-align: center;
            padding: 48px 24px;
            color: #9ca3af;
        }
        .empty-state i { font-size: 2.5rem; opacity: .35; display: block; margin-bottom: 10px; }

        /* ── Print ───────────────────────────────────────────────── */
        @media print {
            body { background: #fff; }
            .lv-toolbar { display: none !important; }
            .lv-paper {
                margin: 0; padding: 0;
                border: 0; box-shadow: none;
                max-width: none;
                border-radius: 0;
            }
            table.report-table thead { display: table-header-group; }
            tr { page-break-inside: avoid; }
        }
    </style>
</head>
<body>
    <div class="lv-toolbar">
        <div class="lv-toolbar-left">
            <h1>@yield('title')</h1>
            <div class="meta">@yield('toolbar-meta')</div>
        </div>
        <div class="lv-toolbar-actions">
            <a href="{{ route('admin.reports.index') }}" class="toolbar-btn toolbar-btn-back">
                <i class="bi bi-arrow-left"></i> Kembali
            </a>
            <button type="button" class="toolbar-btn toolbar-btn-print" onclick="window.print()">
                <i class="bi bi-printer"></i> Cetak
            </button>
            @hasSection('download-url')
                <a href="@yield('download-url')" class="toolbar-btn toolbar-btn-download" target="_blank">
                    <i class="bi bi-file-earmark-pdf"></i> Unduh PDF
                </a>
            @endif
        </div>
    </div>

    <div class="lv-paper">
        {{-- Universal report header with logo --}}
        <div class="report-header">
            <div class="report-header-left">
                <div class="report-logo-row">
                    <img src="/logo.png" alt="Labventory" onerror="this.style.display='none'">
                    <span class="report-brand">Labventory</span>
                </div>
                <h2 class="report-title">@yield('title')</h2>
                <p class="report-subtitle">@yield('report-subtitle', 'Sistem Inventaris Laboratorium Kampus')</p>
            </div>
            <div class="report-header-right">
                <div class="report-generated">@yield('toolbar-meta')</div>
            </div>
        </div>

        @yield('content')
    </div>
</body>
</html>
