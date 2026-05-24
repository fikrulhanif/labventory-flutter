<?php

namespace App\Services;

use App\Exceptions\OutOfStockException;
use App\Models\Inventory;
use App\Models\Loan;
use App\Models\LoanStatusHistory;
use App\Models\User;
use App\Support\LoanStateMachine;
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
    // Admin loan workflow transitions
    //
    // Each method runs inside DB::transaction with lockForUpdate on both
    // the loan and the inventory row, validates the transition through
    // LoanStateMachine, mutates state + appends an audit row, and returns
    // the fresh loan model.
    //
    // Validates Requirements 9.3 — 9.5, 10.1 — 10.8, 18.4.
    // ------------------------------------------------------------------

    /**
     * pending -> approved. Stock is intentionally NOT decremented here
     * (Requirement 9.3).
     */
    public function approve(int $loanId, User $actor, ?string $note = null): Loan
    {
        return DB::transaction(function () use ($loanId, $actor, $note): Loan {
            $loan = $this->lockLoan($loanId);

            LoanStateMachine::assertTransition($loan->status, Loan::STATUS_APPROVED);

            $previous = $loan->status;
            $loan->status = Loan::STATUS_APPROVED;
            $loan->save();

            $this->appendHistory($loan, $previous, Loan::STATUS_APPROVED, $actor, $note);

            return $loan->fresh(['user', 'inventory.category']);
        });
    }

    /**
     * pending -> rejected. Persists the admin's rejection reason on the
     * loan row (Requirement 9.4).
     */
    public function reject(int $loanId, User $actor, string $reason): Loan
    {
        return DB::transaction(function () use ($loanId, $actor, $reason): Loan {
            $loan = $this->lockLoan($loanId);

            LoanStateMachine::assertTransition($loan->status, Loan::STATUS_REJECTED);

            $previous = $loan->status;
            $loan->status = Loan::STATUS_REJECTED;
            $loan->reject_reason = $reason;
            $loan->save();

            $this->appendHistory($loan, $previous, Loan::STATUS_REJECTED, $actor, $reason);

            return $loan->fresh(['user', 'inventory.category']);
        });
    }

    /**
     * approved -> borrowed. Decrements inventory stock by 1 atomically
     * and stamps picked_up_at (Requirements 10.1, 10.6, 10.7).
     */
    public function markPickedUp(int $loanId, User $actor, ?string $note = null): Loan
    {
        return DB::transaction(function () use ($loanId, $actor, $note): Loan {
            $loan = $this->lockLoan($loanId);

            LoanStateMachine::assertTransition($loan->status, Loan::STATUS_BORROWED);

            /** @var Inventory $inventory */
            $inventory = Inventory::query()
                ->lockForUpdate()
                ->findOrFail($loan->inventory_id);

            if ($inventory->stock <= 0) {
                throw new OutOfStockException();
            }

            $inventory->stock -= 1;
            $inventory->status = $inventory->stock > 0
                ? Inventory::STATUS_AVAILABLE
                : Inventory::STATUS_OUT_OF_STOCK;
            $inventory->save();

            $previous = $loan->status;
            $loan->status = Loan::STATUS_BORROWED;
            $loan->picked_up_at = now();
            $loan->save();

            $this->appendHistory($loan, $previous, Loan::STATUS_BORROWED, $actor, $note);

            return $loan->fresh(['user', 'inventory.category']);
        });
    }

    /**
     * borrowed -> returned. Increments inventory stock by 1 atomically
     * and stamps returned_at (Requirements 10.4, 10.6, 10.7).
     */
    public function markReturned(int $loanId, User $actor, ?string $note = null): Loan
    {
        return DB::transaction(function () use ($loanId, $actor, $note): Loan {
            $loan = $this->lockLoan($loanId);

            LoanStateMachine::assertTransition($loan->status, Loan::STATUS_RETURNED);

            /** @var Inventory $inventory */
            $inventory = Inventory::query()
                ->lockForUpdate()
                ->findOrFail($loan->inventory_id);

            $inventory->stock += 1;
            $inventory->status = Inventory::STATUS_AVAILABLE;
            $inventory->save();

            $previous = $loan->status;
            $loan->status = Loan::STATUS_RETURNED;
            $loan->returned_at = now();
            $loan->save();

            $this->appendHistory($loan, $previous, Loan::STATUS_RETURNED, $actor, $note);

            return $loan->fresh(['user', 'inventory.category']);
        });
    }

    /**
     * Paginated, filterable list for the admin dashboard.
     * Sorted by created_at DESC (Requirement 9.1).
     *
     * @param  array{status?: string|null, user_id?: int|string|null, inventory_id?: int|string|null, per_page?: int|string|null}  $filters
     */
    public function listForAdmin(array $filters = []): LengthAwarePaginator
    {
        $query = Loan::query()
            ->with(['inventory.category', 'user'])
            ->orderByDesc('created_at');

        $this->applyStatusFilter($query, $filters['status'] ?? null);

        if (! empty($filters['user_id'])) {
            $query->where('user_id', (int) $filters['user_id']);
        }
        if (! empty($filters['inventory_id'])) {
            $query->where('inventory_id', (int) $filters['inventory_id']);
        }

        return $query->paginate($this->resolvePerPage($filters['per_page'] ?? null));
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

    /**
     * Acquire a row-level lock on the loan row before mutating state.
     */
    private function lockLoan(int $loanId): Loan
    {
        /** @var Loan $loan */
        $loan = Loan::query()
            ->lockForUpdate()
            ->findOrFail($loanId);

        return $loan;
    }

    /**
     * Append an audit row to loan_status_history.
     */
    private function appendHistory(
        Loan $loan,
        string $from,
        string $to,
        User $actor,
        ?string $note,
    ): void {
        LoanStatusHistory::create([
            'loan_id' => $loan->id,
            'actor_user_id' => $actor->id,
            'from_status' => $from,
            'to_status' => $to,
            'note' => $note,
            'created_at' => now(),
        ]);
    }
}
