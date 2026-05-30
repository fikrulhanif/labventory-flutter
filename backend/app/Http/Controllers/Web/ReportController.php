<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Services\ReportService;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Symfony\Component\HttpFoundation\Response;

/**
 * Reports landing page + the two PDF download endpoints.
 *
 *   GET /admin/reports               -> form (date range + two report cards)
 *   GET /admin/reports/inventory.pdf -> stream inventory roster PDF
 *   GET /admin/reports/loans.pdf     -> stream loan transactions PDF
 *                                       within a [start_date, end_date] range
 *
 * Validates Requirements 16.1 — 16.5.
 */
class ReportController extends Controller
{
    public function __construct(private readonly ReportService $reports)
    {
    }

    public function index(Request $request): View
    {
        // Pre-fill the form with last 30 days so the user always has a
        // reasonable default range and never sees "Start ≤ End" errors
        // on first paint.
        $end   = Carbon::today();
        $start = $end->copy()->subDays(30);

        return view('reports.index', [
            'defaultStart' => $request->input('start_date', $start->toDateString()),
            'defaultEnd'   => $request->input('end_date', $end->toDateString()),
        ]);
    }

    public function inventory(): Response
    {
        return $this->reports->inventoryPdf();
    }

    /**
     * HTML preview of the inventory roster, rendered with the same
     * data the PDF will use. Lets the admin scan the contents in a
     * tab and choose between Print and Download PDF without first
     * pulling a 1MB binary.
     */
    public function previewInventory(): View
    {
        return view('reports.preview.inventory', $this->reports->inventoryData());
    }

    /**
     * Loan transactions PDF, filtered by `start_date` and `end_date`.
     *
     * The friendly "Start date must be earlier than or equal to end date"
     * check is performed here (not as a Laravel validation rule) so we
     * can flash it back to the form view instead of throwing a 422 PDF
     * download. Per design Requirement 16.4.
     */
    public function loans(Request $request): RedirectResponse|Response
    {
        [$start, $end, $error] = $this->resolveLoanRange($request);
        if ($error !== null) {
            return $error;
        }

        return $this->reports->loanPdf($start, $end);
    }

    /**
     * HTML preview of the loan transactions report. Same date-range
     * validation as `loans()`; on conflict it bounces back to the form
     * with a flash error instead of rendering a half-empty preview.
     */
    public function previewLoans(Request $request): RedirectResponse|View
    {
        [$start, $end, $error] = $this->resolveLoanRange($request);
        if ($error !== null) {
            return $error;
        }

        return view('reports.preview.loans', $this->reports->loanData($start, $end));
    }

    /**
     * Currently borrowed inventory: PDF download.
     */
    public function borrowed(): Response
    {
        return $this->reports->currentlyBorrowedPdf();
    }

    /**
     * Currently borrowed inventory: HTML preview.
     */
    public function previewBorrowed(): View
    {
        return view('reports.preview.borrowed', $this->reports->currentlyBorrowedData());
    }

    /**
     * Most borrowed inventory: PDF download.
     */
    public function popular(Request $request): RedirectResponse|Response
    {
        [$start, $end, $error] = $this->resolveLoanRange($request);
        if ($error !== null) {
            return $error;
        }

        return $this->reports->mostBorrowedPdf($start, $end);
    }

    /**
     * Most borrowed inventory: HTML preview.
     */
    public function previewPopular(Request $request): RedirectResponse|View
    {
        [$start, $end, $error] = $this->resolveLoanRange($request);
        if ($error !== null) {
            return $error;
        }

        return view('reports.preview.popular', $this->reports->mostBorrowedData($start, $end));
    }

    /**
     * Validate and parse the start/end date pair shared by both the
     * preview and the PDF download. Returns either:
     *   [Carbon $start, Carbon $end, null]                — happy path
     *   [Carbon $start, Carbon $end, RedirectResponse]    — start > end
     *
     * @return array{0: Carbon, 1: Carbon, 2: RedirectResponse|null}
     */
    private function resolveLoanRange(Request $request): array
    {
        $validated = $request->validate([
            'start_date' => ['required', 'date'],
            'end_date'   => ['required', 'date'],
        ]);

        $start = Carbon::parse($validated['start_date']);
        $end   = Carbon::parse($validated['end_date']);

        if ($start->gt($end)) {
            $redirect = redirect()
                ->route('admin.reports.index', [
                    'start_date' => $validated['start_date'],
                    'end_date'   => $validated['end_date'],
                ])
                ->with('error', 'Start date must be earlier than or equal to end date');

            return [$start, $end, $redirect];
        }

        return [$start, $end, null];
    }
}
