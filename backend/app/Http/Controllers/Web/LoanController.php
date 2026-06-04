<?php

namespace App\Http\Controllers\Web;

use App\Exceptions\InvalidLoanTransitionException;
use App\Exceptions\OutOfStockException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Web\Loan\RejectLoanRequest;
use App\Models\Loan;
use App\Models\User;
use App\Services\LoanService;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

/**
 * Admin loan workflow.
 *
 *   GET  /admin/loans                  index   — filter status/user/inventory, ordered desc
 *   GET  /admin/loans/{loan}           show    — detail with KTM viewer + status history
 *   POST /admin/loans/{loan}/approve   pending  -> approved
 *   POST /admin/loans/{loan}/reject    pending  -> rejected   (RejectLoanRequest)
 *   POST /admin/loans/{loan}/pickup    approved -> borrowed   (stock -= 1)
 *   POST /admin/loans/{loan}/return    borrowed -> returned   (stock += 1)
 *
 * State transitions are guarded by LoanStateMachine inside LoanService.
 * Invalid transitions surface here as flash errors with the canonical
 * wording from the design.
 *
 * Validates Requirements 9.1 — 9.5, 10.1 — 10.8, 18.4.
 */
class LoanController extends Controller
{
    public function __construct(private readonly LoanService $loans)
    {
    }

    public function index(Request $request): View
    {
        $page = $this->loans->listForAdmin([
            'status' => $request->query('status'),
            'user_id' => $request->query('user_id'),
            'inventory_id' => $request->query('inventory_id'),
            'per_page' => $request->query('per_page', 15),
        ])->withQueryString();

        return view('loans.index', [
            'loans' => $page,
            'selectedStatus' => $request->query('status'),
        ]);
    }

    public function show(Loan $loan): View
    {
        $loan->load([
            'user',
            'inventory.category',
            'statusHistory.actor',
        ]);

        return view('loans.show', [
            'loan' => $loan,
        ]);
    }

    /**
     * Stream the KTM document for admin/laboran viewing.
     *
     * This is a web-guarded (session auth) endpoint separate from the
     * API endpoint at `GET /api/loans/{id}/document` (which uses
     * Sanctum tokens and is intended for mobile students).
     *
     * Admin/laboran already have a valid session cookie so they can
     * access this without any Bearer token. The file is streamed
     * directly from the public disk.
     */
    public function document(Loan $loan): \Symfony\Component\HttpFoundation\Response
    {
        $path = $loan->document;

        if (! $path || ! \Illuminate\Support\Facades\Storage::disk('public')->exists($path)) {
            abort(404, 'KTM document not found.');
        }

        return \Illuminate\Support\Facades\Storage::disk('public')->response($path);
    }

    public function approve(Request $request, Loan $loan): RedirectResponse
    {
        try {
            /** @var User $admin */
            $admin = $request->user();
            $this->loans->approve($loan->id, $admin);
        } catch (InvalidLoanTransitionException) {
            return back()->with('error', 'Only pending loans can be approved or rejected');
        }

        return redirect()
            ->route('admin.loans.show', $loan)
            ->with('success', 'Loan approved.');
    }

    public function reject(RejectLoanRequest $request, Loan $loan): RedirectResponse
    {
        try {
            /** @var User $admin */
            $admin = $request->user();
            $this->loans->reject(
                $loan->id,
                $admin,
                $request->string('reject_reason')->toString(),
            );
        } catch (InvalidLoanTransitionException) {
            return back()->with('error', 'Only pending loans can be approved or rejected');
        }

        return redirect()
            ->route('admin.loans.show', $loan)
            ->with('success', 'Loan rejected.');
    }

    public function pickup(Request $request, Loan $loan): RedirectResponse
    {
        try {
            /** @var User $admin */
            $admin = $request->user();
            $this->loans->markPickedUp($loan->id, $admin);
        } catch (OutOfStockException) {
            return back()->with('error', 'Inventory is out of stock');
        } catch (InvalidLoanTransitionException) {
            return back()->with('error', 'Only approved loans can be marked as borrowed');
        }

        return redirect()
            ->route('admin.loans.show', $loan)
            ->with('success', 'Item handed over to the student.');
    }

    public function return(Request $request, Loan $loan): RedirectResponse
    {
        try {
            /** @var User $admin */
            $admin = $request->user();
            $this->loans->markReturned($loan->id, $admin);
        } catch (InvalidLoanTransitionException) {
            return back()->with('error', 'Only borrowed loans can be marked as returned');
        }

        return redirect()
            ->route('admin.loans.show', $loan)
            ->with('success', 'Return recorded. Stock incremented.');
    }
}
