<?php

namespace App\Services;

use App\Models\Inventory;
use App\Models\Loan;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Carbon;
use Symfony\Component\HttpFoundation\Response;

/**
 * ReportService renders the two admin PDF reports defined in the spec
 * (Requirements 16.1 — 16.5):
 *
 *   - inventoryPdf()         : full inventory roster snapshot
 *   - loanPdf($from, $to)    : loan transactions filtered by created_at
 *                              between [$from, $to] inclusive
 *
 * DomPDF is used via the laravel-dompdf facade so we can keep the
 * markup in plain Blade. The service returns a streamed Response so
 * the controller can hand it directly to the browser without writing
 * the file to disk.
 */
class ReportService
{
    /**
     * Inventory roster PDF: every inventory item, ordered by code, with
     * category, stock, and derived status. The filename embeds today's
     * date for download convenience.
     */
    public function inventoryPdf(): Response
    {
        $data = $this->inventoryData();
        $filename = 'inventory-' . $data['generatedAt']->toDateString() . '.pdf';

        return Pdf::loadView('pdf.inventory', $data)
            ->setPaper('a4', 'portrait')
            ->stream($filename);
    }

    /**
     * Loan transactions PDF, filtered by `created_at` between
     * [$from 00:00:00, $to 23:59:59] inclusive. The caller is
     * responsible for asserting $from <= $to (controller does this so
     * it can flash a friendly error instead of throwing).
     */
    public function loanPdf(Carbon $from, Carbon $to): Response
    {
        $data = $this->loanData($from, $to);
        $filename = 'loans-' . $data['startDate']->toDateString()
            . '_' . $data['endDate']->toDateString() . '.pdf';

        return Pdf::loadView('pdf.loans', $data)
            ->setPaper('a4', 'landscape')
            ->stream($filename);
    }

    /**
     * Currently-borrowed inventory snapshot PDF.
     */
    public function currentlyBorrowedPdf(): Response
    {
        $data = $this->currentlyBorrowedData();
        $filename = 'borrowed-' . $data['generatedAt']->toDateString() . '.pdf';

        return Pdf::loadView('pdf.borrowed', $data)
            ->setPaper('a4', 'landscape')
            ->stream($filename);
    }

    /**
     * Most-borrowed inventory PDF, filtered by `created_at` between
     * [$from, $to] inclusive.
     */
    public function mostBorrowedPdf(Carbon $from, Carbon $to, int $limit = 20): Response
    {
        $data = $this->mostBorrowedData($from, $to, $limit);
        $filename = 'popular-' . $data['startDate']->toDateString()
            . '_' . $data['endDate']->toDateString() . '.pdf';

        return Pdf::loadView('pdf.popular', $data)
            ->setPaper('a4', 'portrait')
            ->stream($filename);
    }

    /**
     * Build the view-data payload for the inventory report. Shared by
     * both the PDF stream (`inventoryPdf`) and the HTML preview view
     * (`reports.preview.inventory`) so the two cannot drift apart.
     *
     * @return array<string, mixed>
     */
    public function inventoryData(): array
    {
        $inventories = Inventory::query()
            ->with('category')
            ->orderBy('code')
            ->get();

        return [
            'inventories' => $inventories,
            'generatedAt' => Carbon::now(),
            'totalItems'  => $inventories->count(),
            'totalStock'  => $inventories->sum('stock'),
        ];
    }

    /**
     * Build the view-data payload for the loan report. Shared by both
     * the PDF stream (`loanPdf`) and the HTML preview view
     * (`reports.preview.loans`).
     *
     * @return array<string, mixed>
     */
    public function loanData(Carbon $from, Carbon $to): array
    {
        $start = $from->copy()->startOfDay();
        $end   = $to->copy()->endOfDay();

        $loans = Loan::query()
            ->with(['user', 'inventory'])
            ->whereBetween('created_at', [$start, $end])
            ->orderByDesc('created_at')
            ->get();

        return [
            'loans'       => $loans,
            'startDate'   => $start,
            'endDate'     => $end,
            'generatedAt' => Carbon::now(),
            'totalLoans'  => $loans->count(),
        ];
    }

    /**
     * Currently borrowed inventory snapshot (Requirements 16.x add-on):
     * one row per inventory item with the count of loans in `borrowed`
     * status and the list of borrowers (name + NIM + borrow / return
     * date). Items with zero active borrowers are omitted so the
     * report stays focused on what's physically out of the lab.
     *
     * @return array<string, mixed>
     */
    public function currentlyBorrowedData(): array
    {
        $borrowedLoans = Loan::query()
            ->where('status', Loan::STATUS_BORROWED)
            ->with(['user', 'inventory.category'])
            ->orderBy('inventory_id')
            ->get();

        // Group by inventory so the report shows one row per item with
        // a stacked list of borrowers underneath.
        $byInventory = $borrowedLoans
            ->groupBy('inventory_id')
            ->map(function ($loans) {
                $first     = $loans->first();
                $inventory = $first->inventory;

                return [
                    'inventory'       => $inventory,
                    'borrowed_count'  => $loans->count(),
                    'available_count' => max(0, ($inventory?->stock ?? 0)),
                    'loans'           => $loans->sortBy('return_date')->values(),
                ];
            })
            ->sortBy(fn ($row) => $row['inventory']?->code ?? '')
            ->values();

        return [
            'rows'              => $byInventory,
            'generatedAt'       => Carbon::now(),
            'totalItems'        => $byInventory->count(),
            'totalBorrowed'     => $borrowedLoans->count(),
        ];
    }

    /**
     * Top-N most-borrowed inventory in a date range (Requirements 16.x
     * add-on). Counts loans by `created_at` regardless of final status
     * so the ranking reflects demand, not just successful pickups.
     *
     * @return array<string, mixed>
     */
    public function mostBorrowedData(Carbon $from, Carbon $to, int $limit = 20): array
    {
        $start = $from->copy()->startOfDay();
        $end   = $to->copy()->endOfDay();

        $rows = Loan::query()
            ->selectRaw('inventory_id, COUNT(*) as loan_count')
            ->whereBetween('created_at', [$start, $end])
            ->groupBy('inventory_id')
            ->orderByDesc('loan_count')
            ->orderBy('inventory_id')
            ->limit($limit)
            ->with(['inventory.category'])
            ->get()
            ->map(function ($row, $index) {
                return [
                    'rank'       => $index + 1,
                    'inventory'  => $row->inventory,
                    'loan_count' => (int) $row->loan_count,
                ];
            });

        return [
            'rows'        => $rows,
            'startDate'   => $start,
            'endDate'     => $end,
            'limit'       => $limit,
            'generatedAt' => Carbon::now(),
            'totalLoans'  => $rows->sum('loan_count'),
        ];
    }
}
