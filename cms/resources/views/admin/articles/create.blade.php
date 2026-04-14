@extends('layouts.admin')
@section('title', 'Artikel Baru')
@section('content')
<h2 class="font-serif text-3xl text-navy mb-6">Artikel Baru</h2>
<form method="POST" action="/articles" enctype="multipart/form-data" class="bg-white p-6 rounded-lg shadow">
    @include('admin.articles._form')
</form>
@endsection
