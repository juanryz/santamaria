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
            'package_id'               => 'required|uuid|exists:packages,id',
            'pic_name'                 => 'required|string',
            'pic_phone'                => 'required|string',
            'pic_relation'             => 'required|in:anak,suami_istri,orang_tua,saudara,lainnya',
            'pic_address'              => 'required|string',
            'deceased_name'            => 'required|string',
            'deceased_dod'             => 'required|date',
            'deceased_religion'        => 'required|in:islam,kristen,katolik,hindu,buddha,konghucu',
            'pickup_address'           => 'required|string',
            'destination_address'      => 'required|string',
            'scheduled_at'             => 'required|date|after:now',
            'estimated_duration_hours' => 'required|numeric|min:0.5|max:24',
            // final_price TIDAK diinput manual — dihitung otomatis dari billing_item_master
            // Bisa di-override oleh Owner/Admin setelah order selesai (via order_billing_items.tambahan/kembali)
            'payment_method'           => 'required|in:cash,transfer',
            'pj_name'                  => 'required|string|max:255',
            'pj_signature'             => 'required|string',
            'officer_name'             => 'required|string|max:255',
            'officer_signature'        => 'required|string',
            'addon_ids'                => 'nullable|array',
            'addon_ids.*'              => 'uuid|exists:add_on_services,id',
            'so_notes'                 => 'nullable|string',
            'estimated_guests'         => 'nullable|integer|min:0',
            'pin'                      => 'nullable|string|min:4',
        ]);

        return DB::transaction(function () use ($request) {
            // 1. Cari atau buat user konsumen
            $user = User::where('phone', $request->pic_phone)
                ->where('role', UserRole::CONSUMER->value)
                ->first();

            if (!$user) {
                $user = User::create([
                    'name'      => $request->pic_name,
                    'phone'     => $request->pic_phone,
                    'role'      => UserRole::CONSUMER->value,
                    'pin'       => $request->pin ?? '1234',
                    'is_active' => true,
                ]);

                $quotaGb = (int) SystemSetting::getValue('consumer_storage_quota_gb', 1);
                ConsumerStorageQuota::create([
                    'user_id'     => $user->id,
                    'quota_bytes' => $quotaGb * 1024 * 1024 * 1024,
                    'used_bytes'  => 0,
                ]);
            }

            // 2. Buat Order — langsung status confirmed
            $orderNumber = 'SM-' . date('Ymd') . '-' . strtoupper(Str::random(4));

            $orderData                            = $request->except(['pin', 'pj_name', 'pj_signature', 'officer_name', 'officer_signature', 'addon_ids']);
            $orderData['order_number']            = $orderNumber;
            $orderData['pic_user_id']             = $user->id;
            $orderData['so_user_id']              = $request->user()->id;
            $orderData['status']                  = 'confirmed';
            $orderData['so_submitted_at']         = now();
            $orderData['payment_status']          = 'unpaid';

            $order = Order::create($orderData);

            // 3. Add-ons
            if ($request->filled('addon_ids')) {
                foreach ($request->addon_ids as $addonId) {
                    \App\Models\OrderAddOn::firstOrCreate([
                        'order_id'          => $order->id,
                        'add_on_service_id' => $addonId,
                    ]);
                }
            }

            // 4. Buat ServiceAcceptanceLetter langsung bertanda tangan (signed)
            $letterNumber = 'SAL-' . now()->format('Ymd') . '-' . str_pad(
                \App\Models\ServiceAcceptanceLetter::whereDate('created_at', today())->count() + 1, 4, '0', STR_PAD_LEFT
            );
            $terms = \App\Models\TermsAndConditions::current();
            \App\Models\ServiceAcceptanceLetter::create([
                'order_id'             => $order->id,
                'letter_number'        => $letterNumber,
                'status'               => 'signed',
                'pj_nama'              => $request->pic_name,
                'pj_no_telp'           => $request->pic_phone,
                'pj_hubungan'          => $request->pic_relation,
                'pj_alamat'            => $request->pic_address,
                'almarhum_nama'        => $request->deceased_name,
                'almarhum_tgl_wafat'   => $request->deceased_dod,
                'almarhum_agama'       => $request->deceased_religion,
                'terms_version'        => $terms?->version,
                'created_by'           => $request->user()->id,
                // PJ signature
                'pj_signature_path'    => $request->pj_signature,
                'pj_signed_at'         => now(),
                // SM Officer signature
                'sm_officer_id'        => $request->user()->id,
                'sm_officer_nama'      => $request->officer_name,
                'sm_signature_path'    => $request->officer_signature,
                'sm_signed_at'         => now(),
            ]);

            // 5. Generate checklist dari package items
            $items   = PackageItem::where('package_id', $request->package_id)->get();
            $religion = $order->deceased_religion ?? 'umum';
            foreach ($items as $item) {
                $targetRole = $item->provider_role ?? $item->category ?? 'gudang';
                OrderChecklist::firstOrCreate([
                    'order_id'  => $order->id,
                    'item_name' => $item->item_name,
                ], [
                    'religion'      => $religion,
                    'item_category' => $item->category ?? 'perlengkapan_fisik',
                    'target_role'   => $targetRole,
                    'provider_role' => $targetRole,
                    'stock_item_id' => $item->stock_item_id,
                    'quantity'      => $item->quantity,
                    'unit'          => $item->unit ?? 'pcs',
                    'is_checked'    => false,
                ]);
            }

            // 6. Group checklist per provider_role dan kirim alarm ke masing-masing
            $roleGroups = $items->groupBy(fn($i) => $i->provider_role ?? $i->category ?? 'gudang');
            foreach ($roleGroups as $role => $roleItems) {
                NotificationService::sendToRole(
                    $role,
                    'ALARM',
                    "Order {$order->order_number} — Siapkan Item!",
                    "{$roleItems->count()} item perlu disiapkan untuk order {$order->order_number}.",
                    ['order_id' => $order->id, 'action' => 'view_checklist']
                );
            }

            // 7. Auto-deduct stok
            $stockResult  = (new StockManagementService())->processOrderConfirmation($order, $request->user()->id);
            $needsRestock = $stockResult['needs_restock'];

            // 8. Auto-generate equipment, billing, attendance
            (new OrderAutoGenerateService())->onOrderConfirmed($order);

            // 9. Cek stok kritis untuk auto-draft ProcurementRequest
            $lowStockItems = [];
            foreach ($items as $item) {
                $stock = StockItem::where('item_name', 'ilike', "%{$item->item_name}%")->first();
                if ($stock) {
                    $itemQty       = $item->quantity ?? 1;
                    $expectedStock = $stock->current_quantity - $itemQty;
                    if ($expectedStock <= $stock->minimum_quantity) {
                        $needsRestock    = true;
                        $lowStockItems[] = ['stock' => $stock, 'qty' => max(1, $stock->minimum_quantity * 2 - $expectedStock)];
                    }
                }
            }
            $order->update(['needs_restock' => $needsRestock]);

            foreach ($lowStockItems as $lsi) {
                $stock    = $lsi['stock'];
                $existing = \App\Models\ProcurementRequest::where('item_name', $stock->item_name)
                    ->whereNotIn('status', ['completed', 'cancelled'])
                    ->exists();

                if (! $existing) {
                    $gudangUser   = User::where('role', UserRole::GUDANG->value)->first();
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

            // 10. Status log
            OrderStatusLog::create([
                'order_id'  => $order->id,
                'user_id'   => $request->user()->id,
                'to_status' => 'confirmed',
                'notes'     => "Order dibuat dan langsung dikonfirmasi oleh SO. Jadwal: {$request->scheduled_at}. Durasi: {$request->estimated_duration_hours} jam.",
            ]);

            // 11. Broadcast BERSAMAAN ke semua pihak
            $itemList  = $items->pluck('item_name')->implode(', ');
            $gudangMsg = $needsRestock
                ? "STOK KRITIS / MINUS setelah order {$order->order_number}! Draft pengadaan telah dibuat. Segera review dan publikasikan di e-Katalog."
                : "Item dibutuhkan: {$itemList}. Segera siapkan stok dan centang checklist.";

            NotificationService::sendToRole(UserRole::GUDANG->value, 'ALARM',
                $needsRestock ? "Stok Kritis — Order {$order->order_number}" : "Order {$order->order_number} — Siapkan Stok!",
                $gudangMsg,
                ['order_id' => $order->id, 'action' => 'view_procurement']
            );

            $stockMsg = $needsRestock
                ? "MENDEKATI BATAS MINIMUM / MINUS untuk order {$order->order_number}! Request pengadaan telah di-draft, tunggu Gudang mempublikasikan ke Supplier."
                : "Order {$order->order_number} dikonfirmasi. Siapkan tracking payment.";
            NotificationService::sendToRole(UserRole::FINANCE->value, 'ALARM',
                $needsRestock ? 'Stok Mengkhawatirkan!' : 'Order Dikonfirmasi',
                $stockMsg,
                ['order_id' => $order->id, 'action' => 'view_order']
            );

            NotificationService::sendToRole(UserRole::DEKOR->value, 'ALARM',
                "Order {$order->order_number} — Konfirmasi Kehadiran!",
                "Jadwal: " . \Carbon\Carbon::parse($request->scheduled_at)->format('d M Y H:i') . ". Lokasi: {$order->destination_address}",
                ['order_id' => $order->id, 'action' => 'confirm_assignment']
            );

            NotificationService::sendToRole(UserRole::KONSUMSI->value, 'ALARM',
                "Order {$order->order_number} — Konfirmasi Kehadiran!",
                "Estimasi tamu: {$order->estimated_guests}. Jadwal: " . \Carbon\Carbon::parse($request->scheduled_at)->format('d M Y H:i'),
                ['order_id' => $order->id, 'action' => 'confirm_assignment']
            );

            dispatch(new \App\Jobs\AssignPemukaAgama($order));
            dispatch(new \App\Jobs\GenerateInvoiceDraft($order));

            if ($order->pic_user_id) {
                NotificationService::send($order->pic_user_id, 'HIGH',
                    'Order Dikonfirmasi',
                    "Order {$order->order_number} Anda telah dikonfirmasi. Tim kami sedang mempersiapkan layanan.",
                    ['order_id' => $order->id]
                );
            }

            NotificationService::sendToRole(UserRole::OWNER->value, 'HIGH',
                'Order Baru Dikonfirmasi',
                "Order {$order->order_number} dikonfirmasi oleh SO. Nilai: Rp " . number_format($order->final_price, 0, ',', '.'),
                ['order_id' => $order->id]
            );

            return response()->json([
                'success' => true,
                'data'    => $order->fresh(),
                'message' => 'Order dibuat dan dikonfirmasi. Semua pihak sudah mendapat notifikasi.',
            ], 201);
        });
    }

    /**
     * PUT /so/orders/{id}/confirm — DEPRECATED v2.0
     * Order confirmation now happens atomically in store().
     * This endpoint is kept for backward compatibility only.
     */
    public function confirm(Request $request, $id)
    {
        $order = Order::findOrFail($id);

        if ($order->status === 'confirmed') {
            return response()->json([
                'success'    => false,
                'message'    => 'Order sudah dikonfirmasi. Mulai dari versi terbaru, konfirmasi dilakukan saat pembuatan order.',
                'error_code' => 'ORDER_ALREADY_CONFIRMED',
            ], 422);
        }

        return response()->json([
            'success'    => false,
            'message'    => 'Endpoint ini sudah tidak digunakan. Gunakan POST /so/orders untuk membuat dan mengkonfirmasi order sekaligus.',
            'error_code' => 'ENDPOINT_DEPRECATED',
        ], 410);
    }

    public function submit($id, Request $request)
    {
        $request->validate([
            'package_id'               => 'required|uuid|exists:packages,id',
            'addon_ids'                => 'nullable|array',
            'addon_ids.*'              => 'uuid|exists:add_on_services,id',
            'scheduled_at'             => 'required|date|after:now',
            'estimated_duration_hours' => 'required|numeric|min:0.5|max:24',
            'payment_method'           => 'required|in:cash,transfer',
            'so_notes'                 => 'nullable|string',
            'estimated_guests'         => 'nullable|integer',
            // final_price TIDAK diinput manual — dihitung dari billing_item_master
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
                'package_id'               => $request->package_id,
                'scheduled_at'             => $request->scheduled_at,
                'estimated_duration_hours' => $request->estimated_duration_hours,
                'payment_method'           => $request->payment_method,
                'so_notes'                 => $request->so_notes,
                'estimated_guests'         => $request->estimated_guests ?? $order->estimated_guests,
                'so_user_id'               => $request->user()->id,
                'so_submitted_at'          => now(),
                // final_price tidak diset manual — GenerateInvoiceDraft job akan hitung dari billing_item_master
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
