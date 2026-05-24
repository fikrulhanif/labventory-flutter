<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Inventory;
use App\Models\Loan;
use App\Models\User;
use Illuminate\Contracts\View\View;

/**
 * Dashboard home page for the admin / laboran sidebar entry.
 *
 *   GET /admin   admin.dashboard
 *
 * Validates Requirements 14.1, 14.2, 14.3.
 *
 * Every statistic is recomputed on each page load — no caching — so the
 * dashboard never disagrees with the live database state.
 */
class DashboardController extends Controller
{
    public function index(): View
    {
        $stats = [
            'total_inventories' => Inventory::query()->count(),
            'total_students' => User::query()->where('role', User::ROLE_STUDENT)->count(),
            'total_loans' => Loan::query()->count(),
            'available_count' => Inventory::query()->where('stock', '>', 0)->count(),
            'borrowed_count' => Loan::query()->where('status', Loan::STATUS_BORROWED)->count(),
        ];

        $recentLoans = Loan::query()
            ->with(['user:id,name,nim,email', 'inventory:id,name,code'])
            ->orderByDesc('created_at')
            ->limit(5)
            ->get();

        return view('dashboard.index', [
            'stats' => $stats,
            'recentLoans' => $recentLoans,
        ]);
    }
}
