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
    /**
     * Infer legacy category from provider_role for backward compat.
     */
    private function inferCategory(string $providerRole): string
    {
        return match ($providerRole) {
            'gudang'     => 'gudang',
            'laviore'    => 'dekor',
            'konsumsi'   => 'konsumsi',
            'purchasing' => 'dokumen',
            default      => 'lainnya',
        };
    }

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
            'items.*.stock_item_id'      => 'nullable|uuid|exists:stock_items,id',
            'items.*.item_name'          => 'required_with:items|string|max:255',
            'items.*.quantity'           => 'required_with:items|integer|min:1',
            'items.*.unit'               => 'required_with:items|string|max:50',
            'items.*.category'           => 'nullable|string|max:100',
            'items.*.provider_role'      => 'nullable|string|max:50',
            'items.*.fulfillment_notes'  => 'nullable|string',
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
                // If provider_role given but no category, infer category
                if (!empty($item['provider_role']) && empty($item['category'])) {
                    $item['category'] = $this->inferCategory($item['provider_role']);
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
            'stock_item_id'     => 'nullable|uuid|exists:stock_items,id',
            'item_name'         => 'required|string|max:255',
            'quantity'          => 'required|integer|min:1',
            'unit'              => 'required|string|max:50',
            'category'          => 'nullable|string|max:100',
            'provider_role'     => 'nullable|string|max:50',
            'fulfillment_notes' => 'nullable|string',
        ]);

        if (!empty($data['stock_item_id'])) {
            $stock = StockItem::find($data['stock_item_id']);
            if ($stock) {
                $data['item_name'] = $stock->item_name;
                $data['unit']      = $stock->unit;
            }
        }

        // If provider_role given but no category, infer category
        if (!empty($data['provider_role']) && empty($data['category'])) {
            $data['category'] = $this->inferCategory($data['provider_role']);
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
            'stock_item_id'     => 'nullable|uuid|exists:stock_items,id',
            'item_name'         => 'sometimes|string|max:255',
            'quantity'          => 'sometimes|integer|min:1',
            'unit'              => 'sometimes|string|max:50',
            'category'          => 'sometimes|nullable|string|max:100',
            'provider_role'     => 'sometimes|nullable|string|max:50',
            'fulfillment_notes' => 'sometimes|nullable|string',
        ]);

        if (!empty($data['stock_item_id'])) {
            $stock = StockItem::find($data['stock_item_id']);
            if ($stock) {
                $data['item_name'] = $stock->item_name;
                $data['unit']      = $stock->unit;
            }
        }

        // If provider_role given but no category, infer category
        if (!empty($data['provider_role']) && empty($data['category'])) {
            $data['category'] = $this->inferCategory($data['provider_role']);
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
    // Accepts optional ?owner_role= query param to filter by role
    public function stockItems(Request $request): JsonResponse
    {
        $query = StockItem::orderBy('item_name');

        if ($request->filled('owner_role')) {
            $query->where('owner_role', $request->query('owner_role'));
        }

        $items = $query->get(['id', 'item_name', 'category', 'owner_role', 'unit', 'current_quantity', 'minimum_quantity']);

        return response()->json(['success' => true, 'data' => $items]);
    }

    // GET /admin/provider-roles — list semua provider role yang bisa menjadi penyedia item
    public function providerRoles(): JsonResponse
    {
        $roles = \App\Models\Role::where('is_active', true)
            ->where(function ($q) {
                $q->where('can_have_inventory', true)
                  ->orWhere('is_vendor', true)
                  ->orWhere('slug', 'purchasing')
                  ->orWhere('slug', 'gudang');
            })
            ->orderBy('sort_order')
            ->get(['slug', 'label', 'color_hex', 'icon_name']);

        return response()->json(['success' => true, 'data' => $roles]);
    }
}
