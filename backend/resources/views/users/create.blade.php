@extends('layouts.admin')
@section('title', 'New student')
@section('content')
    <nav aria-label="breadcrumb" style="margin-bottom:16px;">
        <ol class="breadcrumb" style="font-size:.75rem;margin:0;">
            <li class="breadcrumb-item"><a href="{{ route('admin.users.index') }}">Students</a></li>
            <li class="breadcrumb-item active">New</li>
        </ol>
    </nav>
    <div class="lv-page-header">
        <div><h1>New student account</h1><p>Create a managed student login.</p></div>
        <a href="{{ route('admin.users.index') }}" class="btn btn-ghost btn-sm"><i class="bi bi-arrow-left me-1"></i>Back</a>
    </div>
    <div class="lv-card" style="max-width:680px;">
        <div class="lv-card-header"><span class="lv-card-title"><i class="bi bi-person-plus me-2 text-primary"></i>Student details</span></div>
        <div style="padding:24px;">
            <form method="POST" action="{{ route('admin.users.store') }}" novalidate>
                @include('users._form', ['submitLabel'=>'Create student','isCreate'=>true])
            </form>
        </div>
    </div>
@endsection
