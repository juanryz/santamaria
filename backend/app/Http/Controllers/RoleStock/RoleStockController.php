<?php
namespace App\Http\Controllers\RoleStock;

use App\Http\Controllers\Controller;
use App\Models\StockItem;
use App\Models\StockTransaction;
use App\Models\OrderChecklist;
use Illuminate\Http\Request;

class RoleStockController extends Controller
{
    private function myRole(Request $request): string {
        return $request->user()->role;
    }

    // GET /role-stock/items — my stock items
    public function index(Request $request) {
        $items = StockItem::where('owner_role', $this->myRole($request))
            ->orderBy('item_name')->get();
        return response()->json(['success' => true, 'data' => $items]);
    }

    // POST /role-stock/items
    public function store(Request $request) {
        $roleModel = \App\Models\Role::findBySlug($this->myRole($request));
        if ($roleModel && !$roleModel->can_have_inventory) {
            return response()->json(['success' => false, 'message' => 'Role Anda tidak memiliki akses inventaris.'], 403);
        }
        $data = $request->validate([
            'item_name'        => 'required|string|max:255',
            'category'         => 'required|string|max:100',
            'current_quantity' => 'required|integer|min:0',
            'minimum_quantity' => 'nullable|integer|min:0',
            'unit'             => 'required|string|max:50',
        ]);
        $data['owner_role'] = $this->myRole($request);
        $data['last_updated_by'] = $request->user()->id;

        // Unique per role
        $exists = StockItem::where('owner_role', $data['owner_role'])
            ->where('item_name', $data['item_name'])->exists();
        if ($exists) return response()->json(['success' => false, 'message' => 'Item sudah ada di inventaris Anda.'], 422);

        $item = StockItem::create($data);
        return response()->json(['success' => true, 'data' => $item], 201);
    }

    // PUT /role-stock/items/{id}
    public function update(Request $request, string $id) {
        $roleModel = \App\Models\Role::findBySlug($this->myRole($request));
        if ($roleModel && !$roleModel->can_have_inventory) {
            return response()->json(['success' => false, 'message' => 'Role Anda tidak memiliki akses inventaris.'], 403);
        }
        $item = StockItem::where('owner_role', $this->myRole($request))->findOrFail($id);
        $data = $request->validate([
            'current_quantity' => 'sometimes|integer|min:0',
            'minimum_quantity' => 'nullable|integer|min:0',
            'category'         => 'sometimes|string|max:100',
        ]);
        $data['last_updated_by'] = $request->user()->id;
        $item->update($data);
        return response()->json(['success' => true, 'data' => $item]);
    }

    // DELETE /role-stock/items/{id}
    public function destroy(Request $request, string $id) {
        $roleModel = \App\Models\Role::findBySlug($this->myRole($request));
        if ($roleModel && !$roleModel->can_have_inventory) {
            return response()->json(['success' => false, 'message' => 'Role Anda tidak memiliki akses inventaris.'], 403);
        }
        $item = StockItem::where('owner_role', $this->myRole($request))->findOrFail($id);
        $item->delete();
        return response()->json(['success' => true, 'message' => 'Item dihapus.']);
    }

    // GET /role-stock/orders/{orderId}/checklist — items this role needs to fulfill
    public function orderChecklist(Request $request, string $orderId) {
        $role = $this->myRole($request);
        $items = OrderChecklist::where('order_id', $orderId)
            ->where(fn($q) => $q->where('target_role', $role)->orWhere('provider_role', $role))
            ->with('order:id,order_number,deceased_name,scheduled_at')
            ->get();
        return response()->json(['success' => true, 'data' => $items]);
    }

    // PUT /role-stock/checklist/{id}/check — mark item fulfilled
    public function checkItem(Request $request, string $id) {
        $role = $this->myRole($request);
        $item = OrderChecklist::where(fn($q) => $q->where('target_role', $role)->orWhere('provider_role', $role))
            ->findOrFail($id);

        $item->update([
            'is_checked' => true,
            'checked_by' => $request->user()->id,
            'checked_at' => now(),
            'notes'      => $request->input('notes'),
        ]);

        // Deduct from this role's stock if stock_item_id set
        if ($item->stock_item_id) {
            $stock = StockItem::where('owner_role', $role)->find($item->stock_item_id);
            if ($stock && $stock->current_quantity >= ($item->quantity ?? 1)) {
                $stock->decrement('current_quantity', $item->quantity ?? 1);
                StockTransaction::create([
                    'stock_item_id' => $stock->id,
                    'order_id'      => $item->order_id,
                    'type'          => 'out',
                    'quantity'      => $item->quantity ?? 1,
                    'notes'         => "Pemenuhan order #{$item->order_id}",
                    'user_id'       => $request->user()->id,
                    'created_at'    => now(),
                ]);
            }
        }

        return response()->json(['success' => true, 'data' => $item->fresh()]);
    }

    // PUT /role-stock/checklist/{id}/uncheck
    public function uncheckItem(Request $request, string $id) {
        $role = $this->myRole($request);
        $item = OrderChecklist::where(fn($q) => $q->where('target_role', $role)->orWhere('provider_role', $role))
            ->findOrFail($id);
        $item->update(['is_checked' => false, 'checked_by' => null, 'checked_at' => null]);
        return response()->json(['success' => true, 'data' => $item->fresh()]);
    }
}
