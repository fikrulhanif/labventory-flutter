<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Inventory Report</title>
    <style>
        @page { margin: 24mm 18mm 22mm 18mm; }
        body  { font-family: DejaVu Sans, sans-serif; color: #1f2937; font-size: 10.5pt; }
        h1    { font-size: 16pt; margin: 0 0 4pt 0; color: #111827; }
        .muted{ color: #6b7280; font-size: 9pt; }
        .meta { margin-top: 14pt; margin-bottom: 14pt; }
        .meta td { padding: 1pt 12pt 1pt 0; font-size: 9pt; }
        .meta .label { color: #6b7280; }

        table.data { width: 100%; border-collapse: collapse; margin-top: 6pt; }
        table.data th, table.data td {
            border-bottom: 0.6pt solid #e5e7eb;
            padding: 6pt 5pt;
            text-align: left;
            vertical-align: top;
        }
        table.data thead th {
            background: #f3f4f6;
            border-bottom: 0.8pt solid #d1d5db;
            font-size: 9.5pt;
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }
        table.data td.num { text-align: right; }
        .pill {
            display: inline-block;
            padding: 1pt 6pt;
            border-radius: 10pt;
            font-size: 8.5pt;
            text-transform: uppercase;
            letter-spacing: 0.03em;
        }
        .pill-available  { background: #d1fae5; color: #065f46; }
        .pill-out        { background: #e5e7eb; color: #4b5563; }

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
    <h1>Inventory Report</h1>
    <div class="muted">Snapshot of every inventory item registered with Labventory.</div>

    <table class="meta">
        <tr>
            <td class="label">Generated</td>
            <td>{{ $generatedAt->toDayDateTimeString() }} UTC</td>
            <td class="label">Items</td>
            <td>{{ number_format($totalItems) }}</td>
            <td class="label">Total stock</td>
            <td>{{ number_format($totalStock) }}</td>
        </tr>
    </table>

    <table class="data">
        <thead>
            <tr>
                <th style="width: 14%;">Code</th>
                <th>Name</th>
                <th style="width: 18%;">Category</th>
                <th class="num" style="width: 9%;">Stock</th>
                <th style="width: 14%;">Status</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($inventories as $item)
                <tr>
                    <td><strong>{{ $item->code }}</strong></td>
                    <td>{{ $item->name }}</td>
                    <td>{{ $item->category?->name ?? '—' }}</td>
                    <td class="num">{{ number_format($item->stock) }}</td>
                    <td>
                        @if ($item->status === 'available')
                            <span class="pill pill-available">available</span>
                        @else
                            <span class="pill pill-out">out of stock</span>
                        @endif
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="5" class="muted" style="text-align:center; padding: 18pt 0;">
                        No inventory records.
                    </td>
                </tr>
            @endforelse
        </tbody>
    </table>

    <div class="footer">
        Labventory · Inventory Report · {{ $generatedAt->toDateString() }}
    </div>
</body>
</html>
