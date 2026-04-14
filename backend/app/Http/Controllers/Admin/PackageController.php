<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Package;
use App\Models\PackageItem;
use App\Models\StockItem;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Manajemen Paket — diakses oleh Admin (dan Owner sebagai read-only via /owner/packages).
 * Tiap PackageItem bisa dikaitkan ke StockItem (stock_item_id)
 * sehingga deduction stok saat order berjalan akurat.
 */
class PackageController extends Controller
{
    // GET /admin/packages
    public function index(): JsonResponse
    {
        $packages = Package::with(['items.stockItem:id,item_name,unit,current_quantity,minimum_quantity'])
            ->orderBy('name')
            ->get();

        return response()->json(['success' => true, 'data' => $packages]);
    }

    // GET /admin/packages/{id}
    public function show(string $id): JsonResponse
    {
        $package = Package::with(['items.stockItem:id,item_name,unit,current_quantity,minimum_quantity'])
            ->findOrFail($id);

        return response()->json(['success' => true, 'data' => $package]);
    }

    // POST /admin/packages
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'              => 'required|string|max:255|unique:packages,name',
            'description'       => 'nullable|string',
            'base_price'        => 'required|numeric|min:0',
            'religion_specific' => 'nullable|string|max:50',
            'is_active'         => 'boolean',
            'items'             => 'nullable|array',
            'items.*.stock_item_id' => 'nullable|uuid|exists:stock_items,id',
            'items.*.item_name'     => 'required_with:items|string|max:255',
            'items.*.quantity'      => 'required_with:items|integer|min:1',
            'items.*.unit'          => 'required_with:items|string|max:50',
            'items.*.category'      => 'required_with:items|in:gudang,dekor,konsumsi,transportasi,dokumen',
        ]);

        return DB::transaction(function () use ($data) {
            $package = Package::create([
                'name'              => $data['name'],
                'description'       => $data['description'] ?? null,
                'base_price'        => $data['base_price'],
                'religion_specific' => $data['religion_specific'] ?? null,
                'is_active'         => $data['is_active'] ?? true,
            ]);

            foreach ($data['items'] ?? [] as $item) {
                if (!empty($item['stock_item_id'])) {
                    $stock = StockItem::find($item['stock_item_id']);
                    if ($stock) {
                        $item['item_name'] = $stock->item_name;
                        $item['unit']      = $stock->unit;
                    }
                }
                $package->items()->create($item);
            }

            return response()->json([
                'success' => true,
                'data'    => $package->load('items.stockItem'),
                'message' => 'Paket berhasil dibuat.',
            ], 201);
        });
    }

    // PUT /admin/packages/{id}
    public function update(Request $request, string $id): JsonResponse
    {
        $package = Package::findOrFail($id);

        $data = $request->validate([
            'name'              => "sometimes|string|max:255|unique:packages,name,{$id}",
            'description'       => 'nullable|string',
            'base_price'        => 'sometimes|numeric|min:0',
            'religion_specific' => 'nullable|string|max:50',
            'is_active'         => 'sometimes|boolean',
        ]);

        $package->update($data);

        return response()->json([
            'success' => true,
            'data'    => $package->load('items.stockItem'),
            'message' => 'Paket berhasil diperbarui.',
        ]);
    }

    // DELETE /admin/packages/{id}
    public function destroy(string $id): JsonResponse
    {
        $package = Package::findOrFail($id);
        $package->update(['is_active' => false]);

        return response()->json(['success' => true, 'message' => 'Paket dinonaktifkan.']);
    }

    // POST /admin/packages/{id}/items
    public function addItem(Request $request, string $id): JsonResponse
    {
        $package = Package::findOrFail($id);

        $data = $request->validate([
            'stock_item_id' => 'nullable|uuid|exists:stock_items,id',
            'item_name'     => 'required|string|max:255',
            'quantity'      => 'required|integer|min:1',
            'unit'          => 'required|string|max:50',
            'category'      => 'required|in:gudang,dekor,konsumsi,transportasi,dokumen',
        ]);

        if (!empty($data['stock_item_id'])) {
            $stock = StockItem::find($data['stock_item_id']);
            if ($stock) {
                $data['item_name'] = $stock->item_name;
                $data['unit']      = $stock->unit;
            }
        }

        $item = $package->items()->create($data);

        return response()->json([
            'success' => true,
            'data'    => $item->load('stockItem'),
            'message' => 'Item berhasil ditambahkan.',
        ], 201);
    }

    // PUT /admin/packages/{id}/items/{itemId}
    public function updateItem(Request $request, string $id, string $itemId): JsonResponse
    {
        $item = PackageItem::where('package_id', $id)->findOrFail($itemId);

        $data = $request->validate([
            'stock_item_id' => 'nullable|uuid|exists:stock_items,id',
            'item_name'     => 'sometimes|string|max:255',
            'quantity'      => 'sometimes|integer|min:1',
            'unit'          => 'sometimes|string|max:50',
            'category'      => 'sometimes|in:gudang,dekor,konsumsi,transportasi,dokumen',
        ]);

        if (!empty($data['stock_item_id'])) {
            $stock = StockItem::find($data['stock_item_id']);
            if ($stock) {
                $data['item_name'] = $stock->item_name;
                $data['unit']      = $stock->unit;
            }
        }

        $item->update($data);

        return response()->json([
            'success' => true,
            'data'    => $item->fresh()->load('stockItem'),
            'message' => 'Item berhasil diperbarui.',
        ]);
    }

    // DELETE /admin/packages/{id}/items/{itemId}
    public function removeItem(string $id, string $itemId): JsonResponse
    {
        $item = PackageItem::where('package_id', $id)->findOrFail($itemId);
        $item->delete();

        return response()->json(['success' => true, 'message' => 'Item dihapus dari paket.']);
    }

    // GET /admin/stock-items — list stok untuk dropdown saat buat/edit paket
    public function stockItems(): JsonResponse
    {
        $items = StockItem::orderBy('item_name')
            ->get(['id', 'item_name', 'category', 'unit', 'current_quantity', 'minimum_quantity']);

        return response()->json(['success' => true, 'data' => $items]);
    }
}
