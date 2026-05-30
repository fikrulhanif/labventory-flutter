<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Currently Borrowed Inventory</title>
    <style>
        @page { margin: 18mm 14mm; }
        body  { font-family: DejaVu Sans, sans-serif; color: #1f2937; font-size: 9.5pt; }
        h1    { font-size: 15pt; margin: 0 0 4pt 0; color: #111827; }
        .muted{ color: #6b7280; font-size: 8.5pt; }
        .meta { margin: 10pt 0; }
        .meta td { padding: 1pt 12pt 1pt 0; font-size: 8.5pt; }
        .meta .label { color: #6b7280; }

        table.data { width: 100%; border-collapse: collapse; margin-top: 4pt; }
        table.data th, table.data td {
            border-bottom: 0.5pt solid #e5e7eb;
            padding: 5pt 4pt;
            text-align: left;
            vertical-align: top;
        }
        table.data thead th {
            background: #f3f4f6;
            border-bottom: 0.8pt solid #d1d5db;
            font-size: 8.5pt;
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }
        td.num { text-align: right; }
        td.code { font-family: "DejaVu Sans Mono", monospace; font-size: 8.5pt; }

        ul.borrowers { margin: 0; padding: 0; list-style: none; }
        ul.borrowers li {
            padding: 1pt 0;
            border-top: 0.4pt dashed #e5e7eb;
            font-size: 8.5pt;
        }
        ul.borrowers li:first-child { border-top: 0; }

        .footer {
            position: fixed;
            bottom: -10mm;
            left: 0; right: 0;
            font-size: 8pt;
            color: #9ca3af;
            text-align: center;
        }
    </style>
</head>
<body>
    <h1>Currently Borrowed Inventory</h1>
    <div class="muted">Snapshot of items currently checked out of the lab.</div>

    <table class="meta">
        <tr>
            <td class="label">Generated</td>
            <td>{{ $generatedAt->toDayDateTimeString() }} UTC</td>
            <td class="label">Items out</td>
            <td>{{ number_format($totalItems) }}</td>
            <td class="label">Borrowed loans</td>
            <td>{{ number_format($totalBorrowed) }}</td>
        </tr>
    </table>

    <table class="data">
        <thead>
            <tr>
                <th style="width: 11%;">Code</th>
                <th style="width: 18%;">Name</th>
                <th style="width: 12%;">Category</th>
                <th class="num" style="width: 6%;">Stock</th>
                <th class="num" style="width: 8%;">Borrowed</th>
                <th>Borrowers</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($rows as $row)
                <tr>
                    <td class="code"><strong>{{ $row['inventory']?->code }}</strong></td>
                    <td>{{ $row['inventory']?->name }}</td>
                    <td>{{ $row['inventory']?->category?->name ?? '—' }}</td>
                    <td class="num">{{ number_format($row['available_count']) }}</td>
                    <td class="num"><strong>{{ number_format($row['borrowed_count']) }}</strong></td>
                    <td>
                        <ul class="borrowers">
                            @foreach ($row['loans'] as $loan)
                                <li>
                                    <strong>{{ $loan->user?->name ?? '—' }}</strong>
                                    <span class="muted">({{ $loan->user?->nim ?? '' }})</span>
                                    &nbsp;·&nbsp;
                                    {{ $loan->borrow_date?->toDateString() ?? '—' }}
                                    &rarr;
                                    {{ $loan->return_date?->toDateString() ?? '—' }}
                                </li>
                            @endforeach
                        </ul>
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="6" class="muted" style="text-align:center; padding: 18pt 0;">
                        No inventory is currently borrowed.
                    </td>
                </tr>
            @endforelse
        </tbody>
    </table>

    <div class="footer">
        Labventory · Currently Borrowed · {{ $generatedAt->toDateString() }}
    </div>
</body>
</html>
