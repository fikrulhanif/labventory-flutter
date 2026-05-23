<?php

use App\Exceptions\InvalidLoanTransitionException;
use App\Exceptions\KtmAccessDeniedException;
use App\Exceptions\OutOfStockException;
use App\Http\Middleware\EnsureRole;
use App\Http\Middleware\EnsureStudent;
use App\Support\ApiResponse;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'role' => EnsureRole::class,
            'student' => EnsureStudent::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Translate exceptions into the standardized API envelope for
        // any request that expects JSON (Requirements 17.1 — 17.4).
        $exceptions->render(function (ValidationException $e, Request $request) {
            if ($request->expectsJson()) {
                return ApiResponse::validationError($e->errors(), $e->getMessage());
            }
        });

        $exceptions->render(function (AuthenticationException $e, Request $request) {
            if ($request->expectsJson()) {
                return ApiResponse::unauthenticated();
            }
        });

        $exceptions->render(function (AuthorizationException $e, Request $request) {
            if ($request->expectsJson()) {
                return ApiResponse::forbidden($e->getMessage() ?: 'Forbidden');
            }
        });

        $exceptions->render(function (ModelNotFoundException $e, Request $request) {
            if ($request->expectsJson()) {
                return ApiResponse::notFound();
            }
        });

        $exceptions->render(function (NotFoundHttpException $e, Request $request) {
            if ($request->expectsJson()) {
                return ApiResponse::notFound();
            }
        });

        $exceptions->render(function (InvalidLoanTransitionException $e, Request $request) {
            if ($request->expectsJson()) {
                return ApiResponse::error($e->getMessage(), 422);
            }
        });

        $exceptions->render(function (OutOfStockException $e, Request $request) {
            if ($request->expectsJson()) {
                return ApiResponse::error($e->getMessage(), 422);
            }
        });

        $exceptions->render(function (KtmAccessDeniedException $e, Request $request) {
            if ($request->expectsJson()) {
                return ApiResponse::forbidden($e->getMessage());
            }
        });

        // Generic HTTP exceptions (e.g. 404 from a route miss) get the
        // standardized envelope when JSON is expected.
        $exceptions->render(function (HttpExceptionInterface $e, Request $request) {
            if ($request->expectsJson()) {
                $status = $e->getStatusCode();
                $message = match ($status) {
                    404 => 'Resource not found',
                    405 => 'Method not allowed',
                    default => $e->getMessage() ?: 'Server error',
                };

                return ApiResponse::error($message, $status);
            }
        });
    })->create();
