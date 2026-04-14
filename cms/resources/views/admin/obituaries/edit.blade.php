@extends('layouts.admin')
@section('title', 'Edit Berita Duka')
@section('content')
<h2 class="font-serif text-3xl text-navy mb-6">Edit Berita Duka</h2>
<form method="POST" action="/obituaries/{{ $obituary->id }}" enctype="multipart/form-data" class="bg-white p-6 rounded-lg shadow">
    @method('PUT')
    @include('admin.obituaries._form')
</form>
@endsection
