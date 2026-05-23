<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\KtmAccessDeniedException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Loan\StoreLoanRequest;
use App\Http\Resources\LoanResource;
use App\Models\Loan;
use App\Models\User;
use App\Services\LoanService;
use App\Support\ApiResponse;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Mobile-facing loan endpoints.
 *
 *   GET    /api/loans                 — paginated history (own loans)
 *   POST   /api/loans                 — create a pending loan request
 *   GET    /api/loans/{id}            — detail (owner only)
 *   GET    /api/loans/{id}/document   — gated KTM stream (owner or staff)
 *
 * Validates Requirements 8.1 — 8.9, 11.1 — 11.5, 18.6.
 */
class LoanController extends Controller
{
    public function __construct(private readonly LoanService $loans)
    {
    }

    public function index(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $page = $this->loans->listForUser($user, [
            'status' => $request->query('status'),
            'per_page' => $request->query('per_page'),
        ]);

        return ApiResponse::ok(
            LoanResource::collection($page),
            'OK',
        );
    }

    public function store(StoreLoanRequest $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        /** @var \Illuminate\Http\UploadedFile $document */
        $document = $request->file('document');

        $loan = $this->loans->createLoan(
            $user,
            $request->validated(),
            $document,
        );

        return ApiResponse::created(
            new LoanResource($loan),
            'Loan request submitted',
        );
    }

    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $loan = $this->loans->find($id);
        } catch (ModelNotFoundException) {
            return ApiResponse::notFound('Loan not found');
        }

        if (! $request->user()->can('view', $loan)) {
            return ApiResponse::forbidden('Forbidden');
        }

        return ApiResponse::ok(new LoanResource($loan), 'OK');
    }

    /**
     * Stream the KTM document for a loan. Owner OR staff (admin/laboran)
     * may download; everyone else gets 403 (Requirement 18.6).
     */
    public function document(Request $request, int $id): StreamedResponse|JsonResponse
    {
        try {
            $loan = Loan::findOrFail($id);
        } catch (ModelNotFoundException) {
            return ApiResponse::notFound('Loan not found');
        }

        if (! $request->user()->can('downloadDocument', $loan)) {
            throw new KtmAccessDeniedException();
        }

        /** @var \Illuminate\Filesystem\FilesystemAdapter $disk */
        $disk = \Illuminate\Support\Facades\Storage::disk('public');

        if (! $disk->exists($loan->document)) {
            return ApiResponse::notFound('Document not available');
        }

        return $disk->download($loan->document);
    }
}
