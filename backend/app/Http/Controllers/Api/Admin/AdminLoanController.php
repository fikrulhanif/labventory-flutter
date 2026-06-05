<?php

namespace App\Http\Controllers\Api\Admin;

use App\Exceptions\InvalidLoanTransitionException;
use App\Exceptions\OutOfStockException;
use App\Http\Controllers\Controller;
use App\Http\Resources\LoanResource;
use App\Models\User;
use App\Services\LoanService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Admin mobile operations — physical handover and return of a loan.
 *
 * Backs the in-app QR handover/return workflow for admin and laboran
 * users (Requirement 22). Mounted under `auth:sanctum` + `role:admin,laboran`.
 *
 *   POST /api/admin/loans/{loan}/handover   approved -> borrowed (stock -= 1)
 *   POST /api/admin/loans/{loan}/return     borrowed -> returned (stock += 1)
 *
 * Both actions delegate to LoanService::markPickedUp / markReturned, the
 * exact same transactional, lock-guarded paths used by the web dashboard,
 * so the stock-conservation invariant (Property 27) holds identically on
 * both surfaces. Transition / stock errors are translated to the canonical
 * 422 messages (Requirements 22.2, 22.3, 22.5).
 */
class AdminLoanController extends Controller
{
    public function __construct(private readonly LoanService $loans)
    {
    }

    /**
     * Confirm physical handover: approved -> borrowed, stock -1,
     * picked_up_at stamped (Requirement 22.1 — 22.3, 22.6, 22.9).
     */
    public function handover(Request $request, int $loan): JsonResponse
    {
        /** @var User $admin */
        $admin = $request->user();

        try {
            $updated = $this->loans->markPickedUp($loan, $admin);
        } catch (OutOfStockException) {
            return ApiResponse::error('Inventory is out of stock', 422);
        } catch (InvalidLoanTransitionException) {
            return ApiResponse::error('Only approved loans can be marked as borrowed', 422);
        }

        return ApiResponse::ok(
            ['loan' => new LoanResource($updated)],
            'Item handed over to the student.',
        );
    }

    /**
     * Confirm physical return: borrowed -> returned, stock +1,
     * returned_at stamped (Requirement 22.4 — 22.6, 22.9).
     */
    public function return(Request $request, int $loan): JsonResponse
    {
        /** @var User $admin */
        $admin = $request->user();

        try {
            $updated = $this->loans->markReturned($loan, $admin);
        } catch (InvalidLoanTransitionException) {
            return ApiResponse::error('Only borrowed loans can be marked as returned', 422);
        }

        return ApiResponse::ok(
            ['loan' => new LoanResource($updated)],
            'Return recorded. Stock incremented.',
        );
    }
}
