<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\NotificationResource;
use App\Models\User;
use App\Services\NotificationService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * In-app notification REST endpoints.
 *
 *   GET  /api/notifications                — paginated list, newest-first
 *   GET  /api/notifications/unread-count   — { count: N } for badge
 *   POST /api/notifications/{id}/read      — mark one as read
 *   POST /api/notifications/read-all       — mark all as read
 *
 * All endpoints require auth:sanctum. Students call these; staff can
 * too if they ever have notifications, but currently only students
 * receive loan-lifecycle notifications.
 */
class NotificationController extends Controller
{
    public function __construct(private readonly NotificationService $notifications)
    {
    }

    /**
     * GET /api/notifications
     *
     * Accepts optional query params:
     *   - per_page (1-50, default 20)
     *   - unread_only (boolean flag)
     */
    public function index(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $paginator = $this->notifications->listForUser($user, [
            'per_page'    => $request->query('per_page'),
            'unread_only' => filter_var($request->query('unread_only', false), FILTER_VALIDATE_BOOLEAN),
        ]);

        // Wrap in a ResourceCollection so ApiResponse::normalize gives
        // the canonical { items, meta } paginated shape.
        return ApiResponse::ok(
            NotificationResource::collection($paginator),
        );
    }

    /**
     * GET /api/notifications/unread-count
     *
     * Returns { "count": N } — consumed by the Flutter badge.
     */
    public function unreadCount(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        return ApiResponse::ok([
            'count' => $this->notifications->unreadCount($user),
        ]);
    }

    /**
     * POST /api/notifications/{id}/read
     *
     * Marks one notification as read. Silently succeeds even if the id
     * doesn't belong to this user (no info-leak about other users'
     * notification ids).
     */
    public function markRead(Request $request, int $id): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $this->notifications->markRead($user, $id);

        return ApiResponse::message('Notifikasi ditandai telah dibaca.');
    }

    /**
     * POST /api/notifications/read-all
     *
     * Marks every unread notification for this user as read.
     */
    public function markAllRead(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $count = $this->notifications->markAllRead($user);

        return ApiResponse::message("{$count} notifikasi ditandai telah dibaca.");
    }
}
