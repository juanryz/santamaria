@extends('layouts.admin')
@section('title', 'Edit Artikel')
@section('content')
<h2 class="font-serif text-3xl text-navy mb-6">Edit Artikel</h2>
<form method="POST" action="/articles/{{ $article->id }}" enctype="multipart/form-data" class="bg-white p-6 rounded-lg shadow">
    @method('PUT')
    @include('admin.articles._form')
</form>
@endsection
