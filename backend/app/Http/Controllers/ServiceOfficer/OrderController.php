<?php

namespace App\Http\Controllers\ServiceOfficer;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderChecklist;
use App\Models\OrderStatusLog;
use App\Models\Package;
use App\Models\PackageItem;
use App\Models\StockItem;
use App\Services\NotificationService;
use App\Services\StockManagementService;
use App\Services\OrderAutoGenerateService;
use App\Models\User;
use App\Models\ConsumerStorageQuota;
use App\Models\SystemSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrderController extends Controller
{
    public function index(Request $request)
    {
        $userId = $request->user()->id;
        
        // Show orders that are either:
        // 1. Still pending (needs review)
        // 2. Already handled by this SO (track progress)
        $orders = Order::with('pic:id,name,phone')
            ->where(function($query) use ($userId) {
                $query->where('status', 'pending')
                      ->orWhere('so_user_id', $userId);
            })
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $orders
        ]);
    }

    public function show($id)
    {
        $order = Order::with(['pic:id,name,phone', 'package', 'orderAddOns'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $order
        ]);
    }

    public function packages()
    {
        $packages = Package::where('is_active', true)
            ->orderBy('base_price')
            ->get()
            ->map(function ($package) {
                $packageItems = PackageItem::where('package_id', $package->id)
                    ->whereNotNull('stock_item_id')
                    ->with('stockItem')
                    ->get();

                $hasCriticalOut = false;
                $hasLowStock = false;

                foreach ($packageItems as $item) {
                    $stock = $item->stockItem;
                    if (!$stock) continue;

                    $needed = $item->deduct_quantity ?? $item->quantity ?? 1;
                    $available = $stock->current_quantity;

                    if ($available < $needed) {
                        if ($item->is_critical ?? true) {
                            $hasCriticalOut = true;
                        } else {
                            $hasLowStock = true;
                        }
                    } elseif ($available <= ($stock->minimum_quantity ?? 0)) {
                        $hasLowStock = true;
                    }
                }

                $pkg = $package->toArray();
                $pkg['stock_status'] = $hasCriticalOut ? 'out_of_stock'
                    : ($hasLowStock ? 'low_stock' : 'available');
                return $pkg;
            });

        return response()->json([
            'success' => true,
            'data' => $packages
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'package_id' => 'required|uuid|exists:packages,id', // Added mandatory package_id validation
            'pic_name' => 'required|string',
            'pic_phone' => 'required|string',
            'pic_relation' => 'required|in:anak,suami_istri,orang_tua,saudara,lainnya',
            'pic_address' => 'required|string',
            'deceased_name' => 'required|string',
            'deceased_dod' => 'required|date',
            'deceased_religion' => 'required|in:islam,kristen,katolik,hindu,buddha,konghucu',
            'pickup_address' => 'required|string',
            'destination_address' => 'required|string',
            'pin' => 'nullable|string|min:4', // PIN baru jika user belum ada
        ]);

        return DB::transaction(function () use ($request) {
            // 1. Cari atau buat user konsumen
            $user = User::where('phone', $request->pic_phone)
                ->where('role', UserRole::CONSUMER->value)
                ->first();

            if (!$user) {
                $user = User::create([
                    'name' => $request->pic_name,
                    'phone' => $request->pic_phone,
                    'role' => UserRole::CONSUMER->value,
                    'pin' => $request->pin ?? '1234', // Default PIN jika tidak diisi
                    'is_active' => true,
                ]);

                // Create storage quota
                $quotaGb = (int) SystemSetting::getValue('consumer_storage_quota_gb', 1);
                ConsumerStorageQuota::create([
                    'user_id' => $user->id,
                    'quota_bytes' => $quotaGb * 1024 * 1024 * 1024,
                    'used_bytes' => 0
                ]);
            }

            // 2. Buat Order
            $orderNumber = 'SM-' . date('Ymd') . '-' . strtoupper(Str::random(4));
            
            $orderData = $request->except('pin');
            $orderData['order_number'] = $orderNumber;
            $orderData['pic_user_id'] = $user->id;
            $orderData['so_user_id'] = $request->user()->id; // Auto-assign to the SO who created it
            $orderData['status'] = 'pending';

            $order = Order::create($orderData);

            // 3. Log
            OrderStatusLog::create([
                'order_id' => $order->id,
                'user_id' => $request->user()->id,
                'to_status' => 'pending',
                'notes' => 'Order baru dibuat oleh Service Officer'
            ]);

            return response()->json([
                'success' => true,
                'data' => $order,
                'message' => 'Order created successfully'
            ], 201);
        });
    }

    /**
     * PUT /so/orders/{id}/confirm — v1.9 ALUR
     * SO konfirmasi order → sistem broadcast alarm ke semua pihak bersamaan
     */
    public function confirm(Request $request, $id)
    {
        $request->validate([
            'package_id'               => 'required|uuid|exists:packages,id',
            'scheduled_at'             => 'required|date|after:now',
            'estimated_duration_hours' => 'required|numeric|min:0.5|max:24',
            'final_price'              => 'required|numeric|min:0',
            'addon_ids'                => 'nullable|array',
            'addon_ids.*'              => 'uuid|exists:add_on_services,id',
            'so_notes'                 => 'nullable|string',
            'estimated_guests'         => 'nullable|integer|min:0',
        ]);

        $order = Order::where('status', 'pending')->findOrFail($id);

        return DB::transaction(function () use ($order, $request) {
            $package = Package::findOrFail($request->package_id);

            $order->update([
                'package_id'               => $request->package_id,
                'status'                   => 'confirmed',
                'scheduled_at'             => $request->scheduled_at,
                'estimated_duration_hours' => $request->estimated_duration_hours,
                'final_price'              => $request->final_price,
                'so_notes'                 => $request->so_notes,
                'so_user_id'               => $request->user()->id,
                'so_submitted_at'          => now(),
                'estimated_guests'         => $request->estimated_guests ?? $order->estimated_guests,
            ]);

            // Add-ons
            if ($request->filled('addon_ids')) {
                foreach ($request->addon_ids as $addonId) {
                    \App\Models\OrderAddOn::firstOrCreate([
                        'order_id'        => $order->id,
                        'add_on_service_id' => $addonId,
                    ]);
                }
            }

            // Generate checklist dari package items
            $items = PackageItem::where('package_id', $request->package_id)->get();
            $religion = $order->deceased_religion ?? 'umum';
            foreach ($items as $item) {
                // Tentukan target_role dari category item
                $targetRole = match ($item->category) {
                    'gudang'       => 'gudang',
                    'dekor'        => 'dekor',
                    'konsumsi'     => 'konsumsi',
                    'transportasi' => 'gudang',
                    default        => 'gudang',
                };
                OrderChecklist::firstOrCreate([
                    'order_id'  => $order->id,
                    'item_name' => $item->item_name,
                ], [
                    'religion'      => $religion,
                    'item_category' => $item->category ?? 'perlengkapan_fisik',
                    'target_role'   => $targetRole,
                    'stock_item_id' => $item->stock_item_id,
                    'quantity'      => $item->quantity,
                    'unit'          => $item->unit ?? 'pcs',
                    'is_checked'    => false,
                ]);
            }

            // v1.14 — Auto-deduct stok via StockManagementService
            $stockResult = (new StockManagementService())->processOrderConfirmation($order, $request->user()->id);
            $needsRestock = $stockResult['needs_restock'];

            // v1.14 — Auto-generate equipment, billing, attendance
            (new OrderAutoGenerateService())->onOrderConfirmed($order);

            // Legacy: cek stok mendekati minimum untuk auto procurement
            $lowStockItems = [];
            foreach ($items as $item) {
                $stock = \App\Models\StockItem::where('item_name', 'ilike', "%{$item->item_name}%")->first();
                if ($stock) {
                    $itemQty = $item->quantity ?? 1;
                    $expectedStock = $stock->current_quantity - $itemQty;
                    if ($expectedStock <= $stock->minimum_quantity) {
                        $needsRestock = true;
                        $lowStockItems[] = ['stock' => $stock, 'qty' => max(1, $stock->minimum_quantity * 2 - $expectedStock)];
                    }
                }
            }
            $order->update(['needs_restock' => $needsRestock]);

            // Auto-trigger draft ProcurementRequest (e-Katalog) untuk stok kritis
            foreach ($lowStockItems as $lsi) {
                $stock = $lsi['stock'];
                $existing = \App\Models\ProcurementRequest::where('item_name', $stock->item_name)
                    ->whereNotIn('status', ['completed', 'cancelled'])
                    ->exists();

                if (! $existing) {
                    $gudangUser = \App\Models\User::where('role', 'gudang')->first();
                    $gudangUserId = $gudangUser ? $gudangUser->id : $request->user()->id;

                    $prNumber = 'PRQ-' . date('Ymd') . '-' . strtoupper(substr(md5($stock->id . now()), 0, 4));
                    \App\Models\ProcurementRequest::create([
                        'request_number'   => $prNumber,
                        'gudang_user_id'   => $gudangUserId,
                        'order_id'         => $order->id,
                        'item_name'        => $stock->item_name,
                        'category'         => $stock->category,
                        'quantity'         => $lsi['qty'],
                        'unit'             => $stock->unit,
                        'delivery_address' => 'Gudang Santa Maria',
                        'status'           => 'draft',
                    ]);
                }
            }

            OrderStatusLog::create([
                'order_id'    => $order->id,
                'user_id'     => $request->user()->id,
                'from_status' => 'pending',
                'to_status'   => 'confirmed',
                'notes'       => "SO konfirmasi order. Jadwal: {$request->scheduled_at}. Durasi: {$request->estimated_duration_hours} jam.",
            ]);

            // ── BROADCAST BERSAMAAN (< 5 detik) ──────────────────────────────

            // 1. Gudang — ALARM dengan daftar item
            $itemList = $items->pluck('item_name')->implode(', ');
            $gudangMsg = $needsRestock
                ? "STOK KRITIS / MINUS setelah order {$order->order_number}! Draft pengadaan telah dibuat. Segera review dan publikasikan di e-Katalog."
                : "Item dibutuhkan: {$itemList}. Segera siapkan stok dan centang checklist.";

            NotificationService::sendToRole('gudang', 'ALARM',
                $needsRestock ? "Stok Kritis — Order {$order->order_number}" : "Order {$order->order_number} — Siapkan Stok!",
                $gudangMsg,
                ['order_id' => $order->id, 'action' => 'view_procurement']
            );

            // 2. Finance — ALARM
            $stockMsg = $needsRestock
                ? "MENDEKATI BATAS MINIMUM / MINUS untuk order {$order->order_number}! Request pengadaan telah di-draft, tunggu Gudang mempublikasikan ke Supplier."
                : "Order {$order->order_number} dikonfirmasi. Siapkan tracking payment.";
            NotificationService::sendToRole('finance', 'ALARM',
                $needsRestock ? 'Stok Mengkhawatirkan!' : 'Order Dikonfirmasi',
                $stockMsg,
                ['order_id' => $order->id, 'action' => 'view_order']
            );

            // 3. Dekor — ALARM
            NotificationService::sendToRole('dekor', 'ALARM',
                "Order {$order->order_number} — Konfirmasi Kehadiran!",
                "Jadwal: " . \Carbon\Carbon::parse($request->scheduled_at)->format('d M Y H:i') . ". Lokasi: {$order->destination_address}",
                ['order_id' => $order->id, 'action' => 'confirm_assignment']
            );

            // 4. Konsumsi — ALARM
            NotificationService::sendToRole('konsumsi', 'ALARM',
                "Order {$order->order_number} — Konfirmasi Kehadiran!",
                "Estimasi tamu: {$order->estimated_guests}. Jadwal: " . \Carbon\Carbon::parse($request->scheduled_at)->format('d M Y H:i'),
                ['order_id' => $order->id, 'action' => 'confirm_assignment']
            );

            // 5. Pemuka Agama — via AI matching (dispatch job)
            dispatch(new \App\Jobs\AssignPemukaAgama($order));

            // 6. AI generate invoice draft (background)
            dispatch(new \App\Jobs\GenerateInvoiceDraft($order));

            // 6.5. AI auto-assign kendaraan dan driver (dipindah ke fase Gudang agar sinkron)
            // dispatch(new \App\Jobs\AssignDriverToOrder($order));

            // 7. Consumer notif
            if ($order->pic_user_id) {
                NotificationService::send($order->pic_user_id, 'HIGH',
                    'Order Dikonfirmasi',
                    "Order {$order->order_number} Anda telah dikonfirmasi. Tim kami sedang mempersiapkan layanan.",
                    ['order_id' => $order->id]
                );
            }

            // 8. Owner — HIGH
            NotificationService::sendToRole('owner', 'HIGH',
                "Order Baru Dikonfirmasi",
                "Order {$order->order_number} dikonfirmasi oleh SO. Nilai: Rp " . number_format($order->final_price, 0, ',', '.'),
                ['order_id' => $order->id]
            );

            return response()->json([
                'success' => true,
                'data'    => $order,
                'message' => 'Order dikonfirmasi. Semua pihak sudah mendapat notifikasi.',
            ]);
        });
    }

    public function submit($id, Request $request)
    {
        $request->validate([
            'package_id' => 'required|uuid|exists:packages,id',
            'final_price' => 'required|numeric',
            'so_notes' => 'nullable|string',
            'estimated_guests' => 'nullable|integer',
        ]);

        $order = Order::findOrFail($id);

        if ($order->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Order is not in pending status'
            ], 400);
        }

        return DB::transaction(function () use ($order, $request) {
            $order->update([
                'package_id' => $request->package_id,
                'final_price' => $request->final_price,
                'so_notes' => $request->so_notes,
                'estimated_guests' => $request->estimated_guests ?? $order->estimated_guests,
                'so_user_id' => $request->user()->id,
                'so_submitted_at' => now(),
                'status' => 'pending' // Still pending, so it stays on SO list and Admin list as actionable
            ]);

            OrderStatusLog::create([
                'order_id' => $order->id,
                'user_id' => $request->user()->id,
                'from_status' => 'pending',
                'to_status' => 'pending',
                'notes' => 'Layanan telah dilengkapi oleh SO. Menunggu Admin mengatur armada.'
            ]);

            NotificationService::sendToRole(UserRole::ADMIN->value, 'HIGH', 'Data Order Lengkap', "Order {$order->order_number} telah dilengkapi oleh SO.");

            return response()->json([
                'success' => true,
                'data' => $order,
                'message' => 'Order details updated and ready for dispatch'
            ]);
        });
    }

    public function destroy($id)
    {
        $order = Order::findOrFail($id);

        if ($order->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Hanya order dengan status pending yang dapat dihapus.'
            ], 400);
        }

        $order->delete();

        return response()->json([
            'success' => true,
            'message' => 'Order berhasil dihapus.'
        ]);
    }
}
