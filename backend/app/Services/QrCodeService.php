<?php

namespace App\Services;

use App\Models\Inventory;
use Endroid\QrCode\Builder\Builder;
use Endroid\QrCode\Encoding\Encoding;
use Endroid\QrCode\ErrorCorrectionLevel;
use Endroid\QrCode\Writer\PngWriter;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * QrCodeService owns inventory QR generation:
 *
 *   - encodes the inventory `code` string as a 300px PNG QR image via
 *     endroid/qr-code (GD writer)
 *   - persists the image to the public disk under `qrcodes/`
 *   - replaces any previous QR file when regenerating
 *   - writes the relative path back onto the inventory's `qr_code` column
 *
 * Generation is invoked from InventoryService::create / update whenever
 * an inventory `code` is set or changes, per Task 19.1. Failures are
 * logged but do not abort the surrounding inventory transaction — QR
 * is an admin convenience (design §QR codes are unsigned plaintext)
 * and a missing QR image must not break inventory CRUD.
 *
 * Validates Requirements 15.1, 15.2, 15.3, 18.2.
 */
class QrCodeService
{
    public const DISK = 'public';

    public const DIR = 'qrcodes';

    public const SIZE = 300;

    public const MARGIN = 10;

    /**
     * Length of the random suffix appended to QR filenames so identical
     * inventory codes never collide on disk (Requirement 18.2).
     */
    public const RANDOM_TOKEN_LENGTH = 40;

    /**
     * Generate (or regenerate) a QR PNG for the given inventory and
     * persist the resulting relative path on the model.
     *
     * Behaviour:
     *
     *   - filename: `qrcodes/<sanitized-code>-<Str::random(40)>.png`
     *   - if `qr_code` is already set, the previous file is removed
     *     from the public disk before the new path is persisted
     *   - the inventory's `qr_code` column is updated to the new path
     *
     * Returns the new relative path on success, or null when generation
     * failed (e.g. the GD extension is not loaded in the running PHP
     * environment). The inventory row is left untouched on failure.
     */
    public function generateFor(Inventory $inventory): ?string
    {
        $code = (string) $inventory->code;
        if ($code === '') {
            return null;
        }

        try {
            $builder = new Builder(
                writer: new PngWriter(),
                writerOptions: [],
                data: $code,
                encoding: new Encoding('UTF-8'),
                errorCorrectionLevel: ErrorCorrectionLevel::Medium,
                size: self::SIZE,
                margin: self::MARGIN,
            );

            $payload = $builder->build()->getString();
        } catch (\Throwable $e) {
            Log::warning('QrCodeService: PNG generation failed', [
                'inventory_id' => $inventory->id,
                'code' => $code,
                'error' => $e->getMessage(),
            ]);

            return null;
        }

        $path = self::DIR.'/'.$this->buildFilename($code);

        $disk = Storage::disk(self::DISK);

        if (! $disk->put($path, $payload)) {
            Log::warning('QrCodeService: failed to write QR file', [
                'inventory_id' => $inventory->id,
                'path' => $path,
            ]);

            return null;
        }

        $previous = $inventory->qr_code;

        $inventory->qr_code = $path;
        $inventory->save();

        if ($previous !== null && $previous !== '' && $previous !== $path) {
            try {
                $disk->delete($previous);
            } catch (\Throwable $e) {
                Log::warning('QrCodeService: failed to delete previous QR file', [
                    'inventory_id' => $inventory->id,
                    'path' => $previous,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        return $path;
    }

    /**
     * Build a collision-resistant filename of the form
     * `<sanitized-code>-<random40>.png`.
     *
     * The code is slugged so payloads containing slashes, spaces, or
     * other path-meaningful characters cannot escape the `qrcodes/`
     * prefix on disk. The random token (Requirement 18.2) prevents two
     * saves for the same code from overwriting each other and keeps
     * the filename unique per regeneration.
     */
    private function buildFilename(string $code): string
    {
        $slug = Str::slug($code, '-', null);
        if ($slug === '') {
            // `Str::slug` returns "" for codes consisting entirely of
            // non-ASCII characters. Fall back to a hex digest of the
            // raw code so the filename is still deterministic-ish and
            // contains no path separators.
            $slug = substr(hash('sha256', $code), 0, 16);
        }

        return $slug.'-'.Str::random(self::RANDOM_TOKEN_LENGTH).'.png';
    }
}
