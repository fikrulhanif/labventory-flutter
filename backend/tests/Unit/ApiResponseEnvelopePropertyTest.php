<?php

namespace Tests\Unit;

use App\Support\ApiResponse;
use Eris\Generator;
use Eris\TestTrait;
use PHPUnit\Framework\TestCase;

/**
 * Feature: labventory-system, Property 38: API envelope conformance.
 *
 * For any response produced by ApiResponse, the body satisfies the
 * Labventory envelope:
 *   - 2xx success bodies have success=true, a string message, and a `data` field.
 *   - validation (422) bodies have success=false, a string message, and an
 *     `errors` object whose values are arrays of strings.
 *   - 401 / 403 / 404 bodies have success=false and a string message.
 *   - 404 carries the canonical message "Resource not found".
 *
 * Validates: Requirements 17.1, 17.2, 17.3, 17.4.
 *
 * The full HTTP-level envelope check (Property 38 over real routes) lives in
 * tests/Feature once the API endpoints come online in tasks 4 — 6.
 */
class ApiResponseEnvelopePropertyTest extends TestCase
{
    use TestTrait;

    public function test_success_envelope_has_success_true_and_data_field(): void
    {
        $messageGen = Generator\string();
        $statusGen = Generator\elements(200, 201);

        $this->forAll($messageGen, $statusGen)
            ->then(function (string $message, int $status): void {
                $response = ApiResponse::ok(['k' => 'v'], $message, $status);
                $body = $response->getData(true);

                self::assertSame($status, $response->getStatusCode());
                self::assertTrue($body['success']);
                self::assertSame($message, $body['message']);
                self::assertArrayHasKey('data', $body);
            });
    }

    public function test_created_envelope_uses_status_201(): void
    {
        $this->forAll(Generator\string())
            ->then(function (string $message): void {
                $response = ApiResponse::created(['id' => 1], $message);
                self::assertSame(201, $response->getStatusCode());
                self::assertTrue($response->getData(true)['success']);
            });
    }

    public function test_validation_envelope_has_success_false_and_errors_object(): void
    {
        // Generator that produces a non-empty errors map keyed by field name
        // with arrays of error message strings.
        $fieldGen = Generator\elements('nim', 'email', 'password', 'borrow_date', 'document');
        $messageListGen = Generator\vector(
            $this->randomNonEmptyMessageCount(),
            Generator\string(),
        );

        $this->forAll($fieldGen, $messageListGen)
            ->then(function (string $field, array $messages): void {
                $errors = [$field => array_values(array_filter(
                    $messages,
                    static fn ($m) => is_string($m) && $m !== '',
                ))];

                if ($errors[$field] === []) {
                    $errors[$field] = ['required'];
                }

                $response = ApiResponse::validationError($errors);
                $body = $response->getData(true);

                self::assertSame(422, $response->getStatusCode());
                self::assertFalse($body['success']);
                self::assertIsString($body['message']);
                self::assertIsArray($body['errors']);
                foreach ($body['errors'] as $list) {
                    self::assertIsArray($list);
                    foreach ($list as $msg) {
                        self::assertIsString($msg);
                    }
                }
            });
    }

    /**
     * Returns a small positive count so the generated message list always
     * has at least one entry to test against.
     */
    private function randomNonEmptyMessageCount(): int
    {
        return random_int(1, 4);
    }

    public function test_unauthenticated_envelope_has_status_401(): void
    {
        $response = ApiResponse::unauthenticated();
        $body = $response->getData(true);

        self::assertSame(401, $response->getStatusCode());
        self::assertFalse($body['success']);
        self::assertSame('Unauthenticated', $body['message']);
        self::assertArrayNotHasKey('errors', $body);
    }

    public function test_forbidden_envelope_has_status_403(): void
    {
        $this->forAll(Generator\elements('Forbidden', 'You are not authorized for this action.'))
            ->then(function (string $message): void {
                $response = ApiResponse::forbidden($message);
                $body = $response->getData(true);

                self::assertSame(403, $response->getStatusCode());
                self::assertFalse($body['success']);
                self::assertSame($message, $body['message']);
            });
    }

    public function test_not_found_envelope_uses_canonical_message(): void
    {
        $response = ApiResponse::notFound();
        $body = $response->getData(true);

        self::assertSame(404, $response->getStatusCode());
        self::assertFalse($body['success']);
        self::assertSame('Resource not found', $body['message']);
    }
}
