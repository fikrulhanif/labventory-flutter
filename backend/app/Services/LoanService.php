<?php

namespace App\Services;

use App\Exceptions\OutOfStockException;
use App\Models\Inventory;
use App\Models\Loan;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

/**
 * LoanService owns the loan aggregate. Task 6 implements the student-facing
 * "create loan" and "list loan history" paths; admin transitions
 * (approve / reject / pickup / return) land in task 11.
 *
 * Validates Requirements 8.1 — 8.9, 11.1 — 11.5, 18.2.
 */
class LoanService
{
    public const KTM_DISK = 'public';

    public const KTM_DIR = 'ktm';

    public const DEFAULT_PAGE_SIZE = 15;

    public const MAX_PAGE_SIZE = 50;

    /**
     * Create a new loan record for the authenticated student.
     *
     * Runs inside a transaction with `lockForUpdate` on the inventory row
     * so simultaneous students cannot exceed available stock at the
     * moment of submission. Note: stock is NOT decremented here — that
     * happens at pickup time per the design (Requirement 9.3).
     *
     * @param  array{inventory_id: int|string, borrow_date: string, return_date: string, notes?: string|null}  $data
     */
    public function createLoan(User $user, array $data, UploadedFile $ktm): Loan
    {
        return DB::transaction(function () use ($user, $data, $ktm): Loan {
            /** @var Inventory $inventory */
            $inventory = Inventory::query()
                ->lockForUpdate()
                ->findOrFail((int) $data['inventory_id']);

            // Requirement 8.3 — out of stock at submission time
            if ($inventory->stock <= 0) {
                throw new OutOfStockException();
            }

            // Requirement 8.8 — disallow a second pending request for the
            // same student / inventory pair.
            $hasPending = Loan::query()
                ->where('user_id', $user->id)
                ->where('inventory_id', $inventory->id)
                ->where('status', Loan::STATUS_PENDING)
                ->exists();
            if ($hasPending) {
                throw ValidationException::withMessages([
                    'inventory_id' => ['You already have a pending request for this item'],
                ]);
            }

            $documentPath = $this->storeKtm($ktm);

            $loan = Loan::create([
                'user_id' => $user->id,
                'inventory_id' => $inventory->id,
                'borrow_date' => $data['borrow_date'],
                'return_date' => $data['return_date'],
                'status' => Loan::STATUS_PENDING,
                'document' => $documentPath,
                'notes' => $data['notes'] ?? null,
            ]);

            return $loan->fresh(['user', 'inventory.category']);
        });
    }

    /**
     * Paginated history of loans owned by the given student.
     *
     * @param  array{status?: string|null, per_page?: int|string|null}  $filters
     */
    public function listForUser(User $user, array $filters = []): LengthAwarePaginator
    {
        $query = Loan::query()
            ->with(['inventory.category', 'user'])
            ->where('user_id', $user->id)
            ->orderByDesc('created_at');

        $this->applyStatusFilter($query, $filters['status'] ?? null);

        return $query->paginate($this->resolvePerPage($filters['per_page'] ?? null));
    }

    /**
     * Find a loan by id and eager-load common relations.
     */
    public function find(int $id): Loan
    {
        return Loan::with(['inventory.category', 'user'])->findOrFail($id);
    }

    // ------------------------------------------------------------------
    // Internal helpers
    // ------------------------------------------------------------------

    /**
     * @param  Builder<Loan>  $query
     */
    private function applyStatusFilter(Builder $query, ?string $status): void
    {
        if ($status === null || $status === '') {
            return;
        }

        if (! in_array($status, Loan::ALL_STATUSES, true)) {
            return;
        }

        $query->where('status', $status);
    }

    /**
     * @param  int|string|null  $raw
     */
    private function resolvePerPage($raw): int
    {
        if ($raw === null || $raw === '') {
            return self::DEFAULT_PAGE_SIZE;
        }

        $value = (int) $raw;
        if ($value < 1) {
            return self::DEFAULT_PAGE_SIZE;
        }

        return min($value, self::MAX_PAGE_SIZE);
    }

    /**
     * Persist the KTM document on the public disk with a randomized
     * filename (Requirement 18.2). Returns the relative path stored on
     * the loan record (e.g. "ktm/abc.jpg").
     */
    private function storeKtm(UploadedFile $file): string
    {
        $extension = strtolower($file->getClientOriginalExtension())
            ?: $file->guessExtension()
            ?: 'bin';
        $filename = Str::random(40).'.'.$extension;

        return $file->storeAs(self::KTM_DIR, $filename, self::KTM_DISK);
    }
}
