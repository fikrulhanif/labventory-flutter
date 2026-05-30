<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Loan Report</title>
    <style>
        @page { margin: 18mm 14mm 18mm 14mm; }
        body  { font-family: DejaVu Sans, sans-serif; color: #1f2937; font-size: 9.5pt; }
        h1    { font-size: 15pt; margin: 0 0 4pt 0; color: #111827; }
        .muted{ color: #6b7280; font-size: 8.5pt; }
        .meta { margin-top: 10pt; margin-bottom: 10pt; }
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
        table.data td.code  { font-family: "DejaVu Sans Mono", monospace; font-size: 8.5pt; }
        table.data td.muted { color: #6b7280; }

        .pill {
            display: inline-block;
            padding: 1pt 5pt;
            border-radius: 9pt;
            font-size: 8pt;
            text-transform: uppercase;
            letter-spacing: 0.03em;
        }
        .pill-pending  { background: #fef3c7; color: #92400e; }
        .pill-approved { background: #cffafe; color: #155e75; }
        .pill-rejected { background: #e5e7eb; color: #4b5563; }
        .pill-borrowed { background: #e0e7ff; color: #3730a3; }
        .pill-returned { background: #d1fae5; color: #065f46; }

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
    @php
        $pillClasses = [
            'pending'  => 'pill-pending',
            'approved' => 'pill-approved',
            'rejected' => 'pill-rejected',
            'borrowed' => 'pill-borrowed',
            'returned' => 'pill-returned',
        ];
    @endphp

    <h1>Loan Report</h1>
    <div class="muted">
        Loan transactions submitted between {{ $startDate->toDateString() }}
        and {{ $endDate->toDateString() }} (inclusive).
    </div>

    <table class="meta">
        <tr>
            <td class="label">Generated</td>
            <td>{{ $generatedAt->toDayDateTimeString() }} UTC</td>
            <td class="label">Total loans</td>
            <td>{{ number_format($totalLoans) }}</td>
        </tr>
    </table>

    <table class="data">
        <thead>
            <tr>
                <th style="width: 6%;">#</th>
                <th style="width: 16%;">Student</th>
                <th style="width: 18%;">Inventory</th>
                <th style="width: 10%;">Borrow date</th>
                <th style="width: 10%;">Return date</th>
                <th style="width: 10%;">Status</th>
                <th style="width: 12%;">Picked up</th>
                <th style="width: 12%;">Returned</th>
                <th>Notes</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($loans as $loan)
                <tr>
                    <td class="muted">{{ $loan->id }}</td>
                    <td>
                        <strong>{{ $loan->user?->name ?? '—' }}</strong><br>
                        <span class="muted">{{ $loan->user?->nim ?? '' }}</span>
                    </td>
                    <td>
                        {{ $loan->inventory?->name ?? '—' }}<br>
                        <span class="code muted">{{ $loan->inventory?->code ?? '' }}</span>
                    </td>
                    <td>{{ $loan->borrow_date?->toDateString() ?? '—' }}</td>
                    <td>{{ $loan->return_date?->toDateString() ?? '—' }}</td>
                    <td>
                        <span class="pill {{ $pillClasses[$loan->status] ?? 'pill-rejected' }}">
                            {{ $loan->status }}
                        </span>
                    </td>
                    <td class="muted">{{ $loan->picked_up_at?->toDateTimeString() ?? '—' }}</td>
                    <td class="muted">{{ $loan->returned_at?->toDateTimeString() ?? '—' }}</td>
                    <td class="muted">
                        @if ($loan->status === 'rejected' && $loan->reject_reason)
                            <em>Rejected:</em> {{ $loan->reject_reason }}
                        @else
                            {{ $loan->notes ?: '—' }}
                        @endif
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="9" class="muted" style="text-align:center; padding: 18pt 0;">
                        No loans were submitted in this date range.
                    </td>
                </tr>
            @endforelse
        </tbody>
    </table>

    <div class="footer">
        Labventory · Loan Report · {{ $startDate->toDateString() }} → {{ $endDate->toDateString() }}
    </div>
</body>
</html>
