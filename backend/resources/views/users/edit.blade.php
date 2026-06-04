@extends('layouts.admin')
@section('title', 'Edit · '.$user->name)
@section('content')
    <nav aria-label="breadcrumb" style="margin-bottom:16px;">
        <ol class="breadcrumb" style="font-size:.75rem;margin:0;">
            <li class="breadcrumb-item"><a href="{{ route('admin.users.index') }}">Students</a></li>
            <li class="breadcrumb-item"><a href="{{ route('admin.users.show', $user) }}">{{ $user->name }}</a></li>
            <li class="breadcrumb-item active">Edit</li>
        </ol>
    </nav>
    <div class="lv-page-header">
        <div><h1>Edit student</h1><p>{{ $user->name }}</p></div>
        <a href="{{ route('admin.users.show', $user) }}" class="btn btn-ghost btn-sm"><i class="bi bi-arrow-left me-1"></i>Back</a>
    </div>
    <div class="lv-card" style="max-width:680px;">
        <div class="lv-card-header"><span class="lv-card-title"><i class="bi bi-pencil me-2 text-primary"></i>Edit details</span></div>
        <div style="padding:24px;">
            <form method="POST" action="{{ route('admin.users.update', $user) }}" novalidate>
                @method('PUT')
                @include('users._form', ['submitLabel'=>'Save changes','isCreate'=>false])
            </form>
        </div>
    </div>
@endsection
