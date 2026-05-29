<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Inventory;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

/**
 * Admin QR scan landing page and code lookup.
 *
 *   GET /admin/qr/scan    -> renders the camera-based scan page
 *   GET /admin/qr/lookup  -> resolves a scanned code to an inventory item
 *                            and redirects to its detail page; on miss
 *                            flashes "Inventory code not found" and
 *                            returns to the scan page
 *
 * Validates Requirements 15.6, 15.7.
 */
class QrController extends Controller
{
    public function scan(): View
    {
        return view('qr.scan');
    }

    public function lookup(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'code' => ['required', 'string', 'max:255'],
        ]);

        $inventory = Inventory::query()
            ->where('code', $validated['code'])
            ->first();

        if ($inventory === null) {
            return redirect()
                ->route('admin.qr.scan')
                ->with('error', 'Inventory code not found');
        }

        return redirect()->route('admin.inventories.show', $inventory);
    }
}
