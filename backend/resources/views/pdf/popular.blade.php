<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Most Borrowed Inventory</title>
    <style>
        @page { margin: 22mm 16mm; }
        body  { font-family: DejaVu Sans, sans-serif; color: #1f2937; font-size: 10pt; }
        h1    { font-size: 16pt; margin: 0 0 4pt 0; color: #111827; }
        .muted{ color: #6b7280; font-size: 9pt; }
        .meta { margin: 10pt 0 14pt 0; }
        .meta td { padding: 1pt 12pt 1pt 0; font-size: 9pt; }
        .meta .label { color: #6b7280; }

        table.data { width: 100%; border-collapse: collapse; margin-top: 4pt; }
        table.data th, table.data td {
            border-bottom: 0.6pt solid #e5e7eb;
            padding: 6pt 5pt;
            text-align: left;
            vertical-align: top;
        }
        table.data thead th {
            background: #f3f4f6;
            border-bottom: 0.8pt solid #d1d5db;
            font-size: 9pt;
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }
        td.num   { text-align: right; }
        td.code  { font-family: "DejaVu Sans Mono", monospace; font-size: 9pt; }
        td.rank  { font-weight: 700; color: #4f46e5; text-align: center; }

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
    <h1>Most Borrowed Inventory</h1>
    <div class="muted">
        Top {{ $limit }} most-requested inventory between {{ $startDate->toDateString() }}
        and {{ $endDate->toDateString() }} (inclusive). Counts every loan submitted in
        the period regardless of final status.
    </div>

    <table class="meta">
        <tr>
            <td class="label">Generated</td>
            <td>{{ $generatedAt->toDayDateTimeString() }} UTC</td>
            <td class="label">Items ranked</td>
            <td>{{ number_format($rows->count()) }}</td>
            <td class="label">Loan count</td>
            <td>{{ number_format($totalLoans) }}</td>
        </tr>
    </table>

    <table class="data">
        <thead>
            <tr>
                <th class="num" style="width: 8%;">#</th>
                <th style="width: 16%;">Code</th>
                <th>Name</th>
                <th style="width: 22%;">Category</th>
                <th class="num" style="width: 14%;">Loan count</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($rows as $row)
                <tr>
                    <td class="rank">{{ $row['rank'] }}</td>
                    <td class="code">{{ $row['inventory']?->code ?? '—' }}</td>
                    <td>{{ $row['inventory']?->name ?? '—' }}</td>
                    <td>{{ $row['inventory']?->category?->name ?? '—' }}</td>
                    <td class="num"><strong>{{ number_format($row['loan_count']) }}</strong></td>
                </tr>
            @empty
                <tr>
                    <td colspan="5" class="muted" style="text-align:center; padding: 18pt 0;">
                        No loans were submitted in this date range.
                    </td>
                </tr>
            @endforelse
        </tbody>
    </table>

    <div class="footer">
        Labventory · Most Borrowed · {{ $startDate->toDateString() }} → {{ $endDate->toDateString() }}
    </div>
</body>
</html>
