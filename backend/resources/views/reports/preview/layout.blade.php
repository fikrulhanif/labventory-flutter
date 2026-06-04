<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title') · Labventory Report</title>
    {{-- All assets served locally — no CDN dependency --}}
    <link href="/vendor/bootstrap/bootstrap.min.css" rel="stylesheet">
    <link href="/vendor/bootstrap-icons/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        :root {
            --lv-bg: #f5f6fa;
            --lv-paper: #ffffff;
            --lv-border: #e5e7eb;
            --lv-muted: #6b7280;
            --lv-primary: #4f46e5;
        }
        body {
            background: var(--lv-bg);
            color: #1f2937;
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
        }

        /* Sticky toolbar so admins can print/download from any scroll position. */
        .lv-toolbar {
            position: sticky;
            top: 0;
            z-index: 100;
            background: #fff;
            border-bottom: 1px solid var(--lv-border);
            padding: 0.85rem 1.5rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 1rem;
            flex-wrap: wrap;
        }
        .lv-toolbar h1 {
            font-size: 1rem;
            font-weight: 600;
            margin: 0;
        }
        .lv-toolbar .meta {
            color: var(--lv-muted);
            font-size: 0.825rem;
        }

        /* "Paper" container that mimics a printed sheet on screen. */
        .lv-paper {
            max-width: 1080px;
            margin: 1.5rem auto;
            padding: 2rem 2.25rem;
            background: var(--lv-paper);
            border: 1px solid var(--lv-border);
            border-radius: 8px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
        }

        .report-header { margin-bottom: 1.25rem; }
        .report-header h2 {
            font-size: 1.4rem;
            font-weight: 700;
            margin: 0 0 0.25rem 0;
        }
        .report-header .lead {
            color: var(--lv-muted);
            font-size: 0.875rem;
            margin: 0;
        }

        .meta-grid {
            display: grid;
            grid-template-columns: auto 1fr auto 1fr;
            gap: 0.35rem 1.5rem;
            margin: 1.25rem 0;
            font-size: 0.85rem;
        }
        .meta-grid .label { color: var(--lv-muted); }

        table.report-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.875rem;
        }
        table.report-table th, table.report-table td {
            border-bottom: 1px solid var(--lv-border);
            padding: 0.55rem 0.5rem;
            text-align: left;
            vertical-align: top;
        }
        table.report-table thead th {
            background: #f3f4f6;
            font-size: 0.75rem;
            text-transform: uppercase;
            letter-spacing: 0.04em;
            color: #4b5563;
        }
        table.report-table td.num { text-align: right; }
        table.report-table td.muted { color: var(--lv-muted); }
        table.report-table td.code  { font-family: ui-monospace, "Cascadia Mono", "Consolas", monospace; }

        .pill {
            display: inline-block;
            padding: 0.15rem 0.55rem;
            border-radius: 999px;
            font-size: 0.7rem;
            text-transform: uppercase;
            letter-spacing: 0.04em;
            font-weight: 600;
        }
        .pill-pending  { background: #fef3c7; color: #92400e; }
        .pill-approved { background: #cffafe; color: #155e75; }
        .pill-rejected { background: #e5e7eb; color: #4b5563; }
        .pill-borrowed { background: #e0e7ff; color: #3730a3; }
        .pill-returned { background: #d1fae5; color: #065f46; }
        .pill-available{ background: #d1fae5; color: #065f46; }
        .pill-out      { background: #e5e7eb; color: #4b5563; }

        .empty-state {
            text-align: center;
            padding: 2.5rem 0;
            color: var(--lv-muted);
        }

        /* Print styles: hide screen-only chrome, fit the paper to the
           page, and let the browser handle pagination. */
        @media print {
            body { background: #fff; }
            .lv-toolbar { display: none !important; }
            .lv-paper {
                margin: 0;
                padding: 0;
                border: 0;
                box-shadow: none;
                max-width: none;
            }
            table.report-table thead {
                display: table-header-group; /* repeat header on each printed page */
            }
            tr { page-break-inside: avoid; }
            a { color: inherit; text-decoration: none; }
        }
    </style>
</head>
<body>
    <div class="lv-toolbar">
        <div>
            <h1>@yield('title')</h1>
            <div class="meta">@yield('toolbar-meta')</div>
        </div>
        <div class="d-flex gap-2 flex-wrap">
            <a href="{{ route('admin.reports.index') }}" class="btn btn-outline-secondary btn-sm">
                <i class="bi bi-arrow-left me-1"></i> Back
            </a>
            <button type="button" class="btn btn-outline-primary btn-sm" onclick="window.print()">
                <i class="bi bi-printer me-1"></i> Print
            </button>
            @hasSection('download-url')
                <a href="@yield('download-url')"
                   class="btn btn-primary btn-sm"
                   target="_blank"
                   rel="noopener">
                    <i class="bi bi-file-earmark-pdf me-1"></i> Download PDF
                </a>
            @endif
        </div>
    </div>

    <div class="lv-paper">
        @yield('content')
    </div>
</body>
</html>
