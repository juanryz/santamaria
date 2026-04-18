<?php

namespace App\Http\Controllers;

use App\Models\PhotoEvidence;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PhotoEvidenceController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'photo' => 'required|image|max:5120',
            'context' => 'required|string|max:100',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'taken_at' => 'required|date',
            'device_id' => 'required|string',
            'order_id' => 'nullable|uuid',
            'reference_type' => 'nullable|string|max:50',
            'reference_id' => 'nullable|uuid',
            'accuracy_meters' => 'nullable|numeric',
            'altitude' => 'nullable|numeric',
            'notes' => 'nullable|string',
        ]);

        $file = $request->file('photo');
        // v1.40: upload via StorageService → R2 (fallback public di dev).
        $storage = app(\App\Services\StorageService::class);
        $path = $storage->uploadPhotoEvidence($file, $request->context, $request->order_id);

        $evidence = PhotoEvidence::create([
            'context' => $request->context,
            'order_id' => $request->order_id,
            'user_id' => $request->user()->id,
            'reference_type' => $request->reference_type,
            'reference_id' => $request->reference_id,
            'file_path' => $path,
            'file_size_bytes' => $file->getSize(),
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'accuracy_meters' => $request->accuracy_meters,
            'altitude' => $request->altitude,
            'taken_at' => $request->taken_at,
            'device_id' => $request->device_id,
            'device_model' => $request->device_model,
            'notes' => $request->notes,
        ]);

        return response()->json(['data' => $evidence], 201);
    }

    public function index(Request $request)
    {
        $query = PhotoEvidence::where('user_id', $request->user()->id);

        if ($request->order_id) {
            $query->where('order_id', $request->order_id);
        }
        if ($request->context) {
            $query->where('context', $request->context);
        }

        return response()->json(['data' => $query->latest('taken_at')->paginate(20)]);
    }
}
