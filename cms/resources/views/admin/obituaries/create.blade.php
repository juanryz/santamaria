@extends('layouts.admin')
@section('title', 'Berita Duka Baru')
@section('content')
<h2 class="font-serif text-3xl text-navy mb-6">Berita Duka Baru</h2>
<form method="POST" action="/obituaries" enctype="multipart/form-data" class="bg-white p-6 rounded-lg shadow">
    @include('admin.obituaries._form')
</form>
@endsection
