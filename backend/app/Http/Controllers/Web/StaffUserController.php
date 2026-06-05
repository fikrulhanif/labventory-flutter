<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Http\Requests\Web\User\StoreStaffUserRequest;
use App\Http\Requests\Web\User\UpdateStaffUserRequest;
use App\Models\User;
use App\Services\AuthService;
use Illuminate\Contracts\View\View;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

/**
 * CRUD for admin/laboran (staff) accounts.
 *
 *   GET    /admin/staff-users                  index
 *   POST   /admin/staff-users/verify-password  verifyPassword  (AJAX)
 *   GET    /admin/staff-users/create           create
 *   POST   /admin/staff-users                  store
 *   GET    /admin/staff-users/{user}/edit      edit
 *   PUT    /admin/staff-users/{user}           update
 *   DELETE /admin/staff-users/{user}           destroy
 *
 * Security model:
 *   - The create/store flow requires the acting admin to prove their own
 *     password via a modal before the create-form is accessible. The
 *     verified state is stored in the session (`staff_create_verified`).
 *   - Only admin/laboran users are reachable here. A 404 is thrown for
 *     student records so the URL can never be used to escalate a student.
 *   - An admin cannot delete their own account.
 */
class StaffUserController extends Controller
{
    public function __construct(private readonly AuthService $auth)
    {
    }

    // ----------------------------------------------------------------
    // Index
    // ----------------------------------------------------------------

    public function index(Request $request): View
    {
        $search = trim((string) $request->query('search', ''));

        $query = User::query()
            ->whereIn('role', [User::ROLE_ADMIN, User::ROLE_LABORAN]);

        if ($search !== '') {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $users = $query->orderBy('name')->paginate(20)->withQueryString();

        return view('staff-users.index', [
            'users'  => $users,
            'search' => $search,
        ]);
    }

    // ----------------------------------------------------------------
    // Password verification (called by the "Tambah Staf" modal via
    // Fetch/XHR before redirecting to the create form).
    // ----------------------------------------------------------------

    /**
     * Verify that the acting admin's password is correct before allowing
     * them to open the create-staff form.
     *
     * Returns JSON so the modal JavaScript can branch without a full
     * page reload.
     */
    public function verifyPassword(Request $request): JsonResponse
    {
        $request->validate([
            'password' => ['required', 'string'],
        ]);

        /** @var User $actor */
        $actor = $request->user();

        if (! Hash::check($request->string('password')->toString(), $actor->password)) {
            return response()->json(['ok' => false, 'message' => 'Kata sandi salah.'], 422);
        }

        // Mark the session so create/store won't demand re-verification
        // within the same browser session window.
        $request->session()->put('staff_create_verified', true);

        return response()->json(['ok' => true]);
    }

    // ----------------------------------------------------------------
    // Create / Store
    // ----------------------------------------------------------------

    public function create(Request $request): View|RedirectResponse
    {
        // If the session flag isn't set, bounce back with an error so a
        // direct GET /admin/staff-users/create without the modal cannot
        // bypass the verification step.
        if (! $request->session()->pull('staff_create_verified')) {
            return redirect()
                ->route('admin.staff-users.index')
                ->with('error', 'Verifikasi kata sandi diperlukan sebelum menambah staf baru.');
        }

        // Re-stamp so the POST (store) can also pass through.
        $request->session()->put('staff_create_verified', true);

        return view('staff-users.create');
    }

    public function store(StoreStaffUserRequest $request): RedirectResponse
    {
        // Double-check the session gate even on the POST path.
        if (! $request->session()->pull('staff_create_verified')) {
            return redirect()
                ->route('admin.staff-users.index')
                ->with('error', 'Verifikasi kata sandi diperlukan. Silakan coba lagi.');
        }

        User::create([
            'name'     => $request->string('name')->toString(),
            'nim'      => null,
            'email'    => $request->string('email')->toString(),
            'password' => Hash::make($request->string('password')->toString()),
            'role'     => $request->input('role'),
            'status'   => $request->input('status', User::STATUS_ACTIVE),
        ]);

        return redirect()
            ->route('admin.staff-users.index')
            ->with('success', 'Akun staf berhasil dibuat.');
    }

    // ----------------------------------------------------------------
    // Edit / Update
    // ----------------------------------------------------------------

    public function edit(User $staffUser): View
    {
        $this->ensureStaff($staffUser);

        return view('staff-users.edit', ['user' => $staffUser]);
    }

    public function update(UpdateStaffUserRequest $request, User $staffUser): RedirectResponse
    {
        $this->ensureStaff($staffUser);

        $staffUser->name   = $request->string('name')->toString();
        $staffUser->email  = $request->string('email')->toString();
        $staffUser->role   = $request->input('role');
        $staffUser->status = $request->input('status', User::STATUS_ACTIVE);

        $newPassword = $request->input('password');
        if ($newPassword !== null && $newPassword !== '') {
            $staffUser->password = Hash::make($newPassword);
        }

        $staffUser->save();

        // If status flipped to inactive, revoke all mobile tokens.
        if ($staffUser->status === User::STATUS_INACTIVE) {
            $this->auth->setInactive($staffUser);
        }

        return redirect()
            ->route('admin.staff-users.index')
            ->with('success', 'Akun staf berhasil diperbarui.');
    }

    // ----------------------------------------------------------------
    // Destroy
    // ----------------------------------------------------------------

    public function destroy(Request $request, User $staffUser): RedirectResponse
    {
        $this->ensureStaff($staffUser);

        // Prevent an admin from deleting their own account.
        if ($staffUser->id === $request->user()?->id) {
            return back()->with('error', 'Anda tidak dapat menghapus akun Anda sendiri.');
        }

        $staffUser->tokens()->delete();
        $staffUser->delete();

        return redirect()
            ->route('admin.staff-users.index')
            ->with('success', 'Akun staf berhasil dihapus.');
    }

    // ----------------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------------

    private function ensureStaff(User $user): void
    {
        abort_unless($user->isStaff(), 404, 'Staff user not found');
    }
}
