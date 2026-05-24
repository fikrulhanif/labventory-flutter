<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Http\Requests\Web\User\StoreUserRequest;
use App\Http\Requests\Web\User\UpdateUserRequest;
use App\Models\Loan;
use App\Models\User;
use App\Services\AuthService;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

/**
 * CRUD for student user accounts.
 *
 *   GET    /admin/users            index   — search by name/nim/email
 *   GET    /admin/users/create     create
 *   POST   /admin/users            store
 *   GET    /admin/users/{user}/edit edit
 *   PUT    /admin/users/{user}     update  — supports status toggle
 *   DELETE /admin/users/{user}     destroy — guarded by active loans
 *
 * The list and the per-user actions are scoped to `role = student` so
 * admin/laboran accounts are never exposed to this UI.
 *
 * Validates Requirements 13.1 — 13.6.
 */
class UserController extends Controller
{
    public function __construct(private readonly AuthService $auth)
    {
    }

    public function index(Request $request): View
    {
        $search = trim((string) $request->query('search', ''));

        $query = User::query()
            ->where('role', User::ROLE_STUDENT)
            ->withCount(['loans as active_loans_count' => function ($q) {
                $q->whereIn('status', [
                    Loan::STATUS_PENDING,
                    Loan::STATUS_APPROVED,
                    Loan::STATUS_BORROWED,
                ]);
            }]);

        if ($search !== '') {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('nim', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $users = $query->orderBy('name')->paginate(15)->withQueryString();

        return view('users.index', [
            'users' => $users,
            'search' => $search,
        ]);
    }

    public function create(): View
    {
        return view('users.create', ['user' => null]);
    }

    public function store(StoreUserRequest $request): RedirectResponse
    {
        User::create([
            'name' => $request->string('name')->toString(),
            'nim' => $request->string('nim')->toString(),
            'email' => $request->string('email')->toString(),
            'password' => Hash::make($request->string('password')->toString()),
            'role' => User::ROLE_STUDENT,
            'status' => $request->input('status', User::STATUS_ACTIVE),
        ]);

        return redirect()
            ->route('admin.users.index')
            ->with('success', 'Student user created.');
    }

    public function edit(User $user): View
    {
        $this->ensureStudent($user);

        return view('users.edit', ['user' => $user]);
    }

    public function update(UpdateUserRequest $request, User $user): RedirectResponse
    {
        $this->ensureStudent($user);

        $previousStatus = $user->status;

        $user->name = $request->string('name')->toString();
        $user->nim = $request->string('nim')->toString();
        $user->email = $request->string('email')->toString();
        $user->status = $request->input('status', User::STATUS_ACTIVE);

        $newPassword = $request->input('password');
        if ($newPassword !== null && $newPassword !== '') {
            $user->password = Hash::make($newPassword);
        }

        $user->save();

        // Requirement 13.4 — toggling to inactive must revoke every
        // Sanctum token belonging to this user.
        if (
            $previousStatus !== User::STATUS_INACTIVE
            && $user->status === User::STATUS_INACTIVE
        ) {
            $this->auth->setInactive($user);
        }

        return redirect()
            ->route('admin.users.index')
            ->with('success', 'Student user updated.');
    }

    public function destroy(User $user): RedirectResponse
    {
        $this->ensureStudent($user);

        $hasActive = Loan::query()
            ->where('user_id', $user->id)
            ->whereIn('status', [
                Loan::STATUS_PENDING,
                Loan::STATUS_APPROVED,
                Loan::STATUS_BORROWED,
            ])
            ->exists();

        if ($hasActive) {
            return back()->with(
                'error',
                'Cannot delete a user with active loans',
            );
        }

        $user->delete();

        return redirect()
            ->route('admin.users.index')
            ->with('success', 'Student user deleted.');
    }

    /**
     * Reject any access to non-student records through this controller.
     */
    private function ensureStudent(User $user): void
    {
        abort_unless($user->isStudent(), 404, 'Student not found');
    }
}
