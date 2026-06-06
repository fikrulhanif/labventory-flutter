<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\Loan;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

/**
 * Creates and manages in-app notifications for students.
 *
 * This is a pure database notification system — NO push notifications,
 * FCM, or WebSockets. The Flutter app polls via REST API.
 *
 * Public entry points:
 *   - notifyLoanCreated()     called by LoanService::createLoan
 *   - notifyLoanApproved()    called by LoanService::approve
 *   - notifyLoanRejected()    called by LoanService::reject
 *   - notifyLoanBorrowed()    called by LoanService::markPickedUp
 *   - notifyLoanReturned()    called by LoanService::markReturned
 *
 * API helpers used by NotificationController:
 *   - listForUser()
 *   - unreadCount()
 *   - markRead()
 *   - markAllRead()
 */
class NotificationService
{
    public const DEFAULT_PAGE_SIZE = 20;

    // ---------------------------------------------------------------
    // Loan lifecycle hooks — called from inside the DB transaction in
    // LoanService (after the transition is committed). All helpers are
    // intentionally simple and do NOT throw so a notification failure
    // never rolls back the parent transaction.
    // ---------------------------------------------------------------

    public function notifyLoanCreated(Loan $loan): void
    {
        $inventoryName = $loan->inventory?->name ?? 'Inventaris';

        $this->create(
            userId: $loan->user_id,
            loanId: $loan->id,
            type: AppNotification::TYPE_LOAN_CREATED,
            title: 'Pengajuan Diterima',
            message: "Pengajuan peminjaman {$inventoryName} berhasil dibuat dan sedang menunggu persetujuan laboran.",
        );
    }

    public function notifyLoanApproved(Loan $loan): void
    {
        $inventoryName = $loan->inventory?->name ?? 'Inventaris';

        $this->create(
            userId: $loan->user_id,
            loanId: $loan->id,
            type: AppNotification::TYPE_LOAN_APPROVED,
            title: 'Pengajuan Disetujui',
            message: "Peminjaman {$inventoryName} telah disetujui. Silakan datang ke laboratorium untuk mengambil inventaris.",
        );
    }

    public function notifyLoanRejected(Loan $loan): void
    {
        $inventoryName = $loan->inventory?->name ?? 'Inventaris';
        $extra = $loan->reject_reason
            ? " Alasan: {$loan->reject_reason}."
            : '';

        $this->create(
            userId: $loan->user_id,
            loanId: $loan->id,
            type: AppNotification::TYPE_LOAN_REJECTED,
            title: 'Pengajuan Ditolak',
            message: "Peminjaman {$inventoryName} ditolak oleh laboran.{$extra}",
        );
    }

    public function notifyLoanBorrowed(Loan $loan): void
    {
        $inventoryName = $loan->inventory?->name ?? 'Inventaris';

        $this->create(
            userId: $loan->user_id,
            loanId: $loan->id,
            type: AppNotification::TYPE_LOAN_BORROWED,
            title: 'Inventaris Diserahkan',
            message: "{$inventoryName} telah berhasil diserahkan kepada Anda.",
        );
    }

    public function notifyLoanReturned(Loan $loan): void
    {
        $inventoryName = $loan->inventory?->name ?? 'Inventaris';

        $this->create(
            userId: $loan->user_id,
            loanId: $loan->id,
            type: AppNotification::TYPE_LOAN_RETURNED,
            title: 'Pengembalian Berhasil',
            message: "Inventaris {$inventoryName} telah berhasil dikembalikan. Terima kasih!",
        );
    }

    // ---------------------------------------------------------------
    // API helpers — used by NotificationController
    // ---------------------------------------------------------------

    /**
     * Paginated list of notifications for a user, newest-first.
     *
     * @param  array{per_page?: int|string|null, unread_only?: bool}  $filters
     */
    public function listForUser(User $user, array $filters = []): LengthAwarePaginator
    {
        $query = AppNotification::query()
            ->where('user_id', $user->id)
            ->orderByDesc('created_at');

        if (! empty($filters['unread_only'])) {
            $query->where('is_read', false);
        }

        $perPage = (int) ($filters['per_page'] ?? self::DEFAULT_PAGE_SIZE);
        $perPage = max(1, min($perPage, 50));

        return $query->paginate($perPage);
    }

    /**
     * Count of unread notifications for a user (used for the badge).
     */
    public function unreadCount(User $user): int
    {
        return AppNotification::query()
            ->where('user_id', $user->id)
            ->where('is_read', false)
            ->count();
    }

    /**
     * Mark a single notification as read. Silently ignores notifications
     * that don't belong to the user (no throw) to prevent enumeration.
     */
    public function markRead(User $user, int $notificationId): void
    {
        AppNotification::query()
            ->where('id', $notificationId)
            ->where('user_id', $user->id)
            ->update(['is_read' => true]);
    }

    /**
     * Mark all notifications for the user as read.
     */
    public function markAllRead(User $user): int
    {
        return AppNotification::query()
            ->where('user_id', $user->id)
            ->where('is_read', false)
            ->update(['is_read' => true]);
    }

    // ---------------------------------------------------------------
    // Internal
    // ---------------------------------------------------------------

    private function create(
        int $userId,
        int $loanId,
        string $type,
        string $title,
        string $message,
    ): AppNotification {
        return AppNotification::create([
            'user_id' => $userId,
            'loan_id' => $loanId,
            'type'    => $type,
            'title'   => $title,
            'message' => $message,
            'is_read' => false,
        ]);
    }
}
