@extends('layouts.admin')

@section('title', 'Students')

@section('content')
    <div class="d-flex flex-wrap align-items-center justify-content-between mb-4 gap-3">
        <div>
            <h1 class="h4 mb-1 fw-semibold">Students</h1>
            <p class="text-muted small mb-0">Manage student accounts that can borrow inventory.</p>
        </div>
        <a href="{{ route('admin.users.create') }}" class="btn btn-primary">
            <i class="bi bi-plus-lg me-1"></i> New student
        </a>
    </div>

    <div class="card border-0 shadow-sm">
        <div class="card-header bg-white py-3 border-0">
            <form method="GET" class="d-flex" role="search">
                <input type="search"
                       name="search"
                       value="{{ $search }}"
                       class="form-control"
                       placeholder="Search by name, NIM, or email…">
                @if ($search !== '')
                    <a href="{{ route('admin.users.index') }}" class="btn btn-light ms-2">Clear</a>
                @endif
            </form>
        </div>

        <div class="card-body p-0">
            @if ($users->isEmpty())
                <div class="text-center text-muted py-5">
                    <i class="bi bi-people display-6 d-block mb-2"></i>
                    No students match these filters.
                </div>
            @else
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="ps-4">Name</th>
                                <th>NIM</th>
                                <th>Email</th>
                                <th>Status</th>
                                <th>Active loans</th>
                                <th class="pe-4 text-end">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($users as $user)
                                <tr>
                                    <td class="ps-4 fw-medium">{{ $user->name }}</td>
                                    <td><span class="text-muted small">{{ $user->nim }}</span></td>
                                    <td><span class="text-muted small">{{ $user->email }}</span></td>
                                    <td>
                                        @if ($user->status === 'active')
                                            <span class="badge text-bg-success">Active</span>
                                        @else
                                            <span class="badge text-bg-secondary">Inactive</span>
                                        @endif
                                    </td>
                                    <td>
                                        <span class="badge text-bg-light border">
                                            {{ $user->active_loans_count }}
                                        </span>
                                    </td>
                                    <td class="pe-4 text-end">
                                        <a href="{{ route('admin.users.edit', $user) }}"
                                           class="btn btn-sm btn-light">
                                            <i class="bi bi-pencil"></i>
                                        </a>
                                        <form method="POST"
                                              action="{{ route('admin.users.destroy', $user) }}"
                                              class="d-inline"
                                              onsubmit="return confirm('Delete this student account? This cannot be undone.');">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit"
                                                    class="btn btn-sm btn-outline-danger"
                                                    @disabled($user->active_loans_count > 0)>
                                                <i class="bi bi-trash"></i>
                                            </button>
                                        </form>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endif
        </div>

        @if ($users->hasPages())
            <div class="card-footer bg-white border-0">
                {{ $users->links() }}
            </div>
        @endif
    </div>
@endsection
