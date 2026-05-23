<?php

namespace App\Support;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Http\Resources\Json\ResourceCollection;

/**
 * Centralized factory for the Labventory API response envelope.
 *
 *   Success: { "success": true,  "message": "...", "data": { ... } }
 *   Error:   { "success": false, "message": "...", "errors"?: { field: [...] } }
 *
 * Validates Requirements 17.1 — 17.4. Every API controller and the global
 * exception handler funnel through this helper so the wire format stays
 * consistent across the codebase.
 */
final class ApiResponse
{
    /**
     * 200 OK with optional payload.
     *
     * @param  mixed  $data
     */
    public static function ok($data = null, string $message = 'OK', int $status = 200): JsonResponse
    {
        return self::success($data, $message, $status);
    }

    /**
     * 201 Created — used for register and loan creation endpoints.
     *
     * @param  mixed  $data
     */
    public static function created($data = null, string $message = 'Created'): JsonResponse
    {
        return self::success($data, $message, 201);
    }

    /**
     * 204-style success response that carries only a message (e.g. logout).
     */
    public static function message(string $message, int $status = 200): JsonResponse
    {
        return self::success(null, $message, $status);
    }

    /**
     * Generic error envelope. Use the more specific helpers below where
     * possible so HTTP statuses and messages stay aligned with the design.
     *
     * @param  array<string, list<string>>|null  $errors
     */
    public static function error(string $message, int $status = 400, ?array $errors = null): JsonResponse
    {
        $body = [
            'success' => false,
            'message' => $message,
        ];

        if ($errors !== null) {
            $body['errors'] = $errors;
        }

        return new JsonResponse($body, $status);
    }

    /**
     * 422 — validation failure (Requirement 17.2).
     *
     * @param  array<string, list<string>>  $errors
     */
    public static function validationError(
        array $errors,
        string $message = 'The given data was invalid.',
    ): JsonResponse {
        return self::error($message, 422, $errors);
    }

    /**
     * 401 — unauthenticated (Requirement 17.3).
     */
    public static function unauthenticated(string $message = 'Unauthenticated'): JsonResponse
    {
        return self::error($message, 401);
    }

    /**
     * 403 — authorization failure (Requirement 17.3).
     */
    public static function forbidden(string $message = 'Forbidden'): JsonResponse
    {
        return self::error($message, 403);
    }

    /**
     * 404 — canonical not-found envelope (Requirement 17.4).
     */
    public static function notFound(string $message = 'Resource not found'): JsonResponse
    {
        return self::error($message, 404);
    }

    /**
     * Internal helper: emit the success envelope, normalizing payload shape.
     *
     * @param  mixed  $data
     */
    private static function success($data, string $message, int $status): JsonResponse
    {
        return new JsonResponse(
            [
                'success' => true,
                'message' => $message,
                'data' => self::normalize($data),
            ],
            $status,
        );
    }

    /**
     * Convert API resources and paginators into the canonical "items + meta"
     * shape so the Flutter client always sees the same structure.
     *
     * @param  mixed  $data
     * @return mixed
     */
    private static function normalize($data)
    {
        if ($data instanceof LengthAwarePaginator) {
            return [
                'items' => $data->items(),
                'meta' => [
                    'current_page' => $data->currentPage(),
                    'last_page' => $data->lastPage(),
                    'per_page' => $data->perPage(),
                    'total' => $data->total(),
                ],
            ];
        }

        if ($data instanceof ResourceCollection) {
            $resource = $data->resource;

            if ($resource instanceof LengthAwarePaginator) {
                return [
                    'items' => $data,
                    'meta' => [
                        'current_page' => $resource->currentPage(),
                        'last_page' => $resource->lastPage(),
                        'per_page' => $resource->perPage(),
                        'total' => $resource->total(),
                    ],
                ];
            }
        }

        if ($data instanceof JsonResource) {
            return $data;
        }

        return $data;
    }
}
