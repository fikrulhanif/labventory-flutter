<?php

namespace Tests\Unit;

use Carbon\CarbonImmutable;
use Eris\Generator;
use Eris\TestTrait;
use PHPUnit\Framework\TestCase;

/**
 * Feature: labventory-system, Property 39: API timestamps are ISO 8601 UTC.
 *
 * For any Carbon timestamp serialized using the canonical Labventory
 * format ("Y-m-d\TH:i:s\Z" in UTC), the resulting string matches the
 * pattern `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$`.
 *
 * Validates: Requirement 17.7.
 *
 * The full feature-level check (against real API resource bodies) lives in
 * tests/Feature once API endpoints come online. This unit test pins the
 * formatting contract that those resources will reuse.
 */
class Iso8601TimestampPropertyTest extends TestCase
{
    use TestTrait;
    private const ISO_8601_UTC = '/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/';

    public function test_format_produces_iso_8601_utc_for_random_timestamps(): void
    {
        $this->forAll(Generator\choose(0, 4_102_444_800))
            ->then(function (int $epoch): void {
                $formatted = CarbonImmutable::createFromTimestamp($epoch, 'UTC')
                    ->format('Y-m-d\TH:i:s\Z');

                self::assertMatchesRegularExpression(self::ISO_8601_UTC, $formatted);
            });
    }

    public function test_format_is_unaffected_by_input_timezone(): void
    {
        $this->forAll(
            Generator\choose(0, 4_102_444_800),
            Generator\elements('UTC', 'Asia/Jakarta', 'America/New_York', 'Europe/Berlin'),
        )
            ->then(function (int $epoch, string $tz): void {
                $a = CarbonImmutable::createFromTimestamp($epoch, 'UTC');
                $b = CarbonImmutable::createFromTimestamp($epoch, $tz)->setTimezone('UTC');

                self::assertSame(
                    $a->format('Y-m-d\TH:i:s\Z'),
                    $b->format('Y-m-d\TH:i:s\Z'),
                );
            });
    }

    public function test_app_default_timezone_is_utc(): void
    {
        // Sanity: APP_TIMEZONE=UTC propagates to PHP's default timezone.
        // This is what makes Eloquent serialize timestamps in UTC.
        self::assertSame('UTC', date_default_timezone_get());
    }
}
