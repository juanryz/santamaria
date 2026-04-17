<?php

namespace App\Http\Controllers\Consumer;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderChecklist;
use App\Models\OrderStatusLog;
use App\Models\PackageItem;
use App\Models\StockItem;
use App\Services\NotificationService;
use App\Services\OrderAutoGenerateService;
use App\Services\StockManagementService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrderController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'pic_name'                 => 'required|string|max:255',
            'pic_phone'                => 'required|string|max:20',
            'pic_relation'             => 'required|in:anak,suami_istri,orang_tua,saudara,lainnya',
            'pic_address'              => 'required|string',
            'deceased_name'            => 'required|string|max:255',
            'deceased_dod'             => 'required|date',
            'deceased_religion'        => 'required|in:islam,kristen,katolik,hindu,buddha,konghucu',
            'pickup_address'           => 'required|string',
            'destination_address'      => 'required|string',
            'funeral_home_id'          => 'nullable|uuid|exists:funeral_homes,id',
            'cemetery_id'              => 'nullable|uuid|exists:cemeteries,id',
            'ktp_photo'                => 'required|image|max:5120',
            'kk_photo'                 => 'required|image|max:5120',
            'notes'             => 'nullable|string',
            'so_code'           => 'nullable|string|max:20',
            // SAL — consumer wajib tanda tangan, SO opsional
            'pj_name'           => 'required|string|max:255',
            'pj_signature'      => 'required|string',
            'officer_name'      => 'nullable|string|max:255',
            'officer_signature' => 'nullable|string',
            // Paket, harga, jadwal, add-on TIDAK bisa diinput consumer
            // Semua ditentukan SO saat konfirmasi order
        ]);

        return DB::transaction(function () use ($request) {
            // 1. Cari SO berdasarkan so_code (opsional) — so_code = nomor HP SO
            $soUser = null;
            if ($request->filled('so_code')) {
                $soUser = \App\Models\User::where('phone', $request->so_code)
                    ->where('role', UserRole::SERVICE_OFFICER->value)
                    ->where('is_active', true)
                    ->first();
                if (!$soUser) {
                    return response()->json([
                        'success'    => false,
                        'message'    => 'Kode SO tidak valid atau SO tidak aktif.',
                        'error_code' => 'INVALID_SO_CODE',
                    ], 422);
                }
            }

            // 2. Consumer selalu buat order dengan status pending
            // Paket, harga, add-on, jadwal ditentukan SO saat konfirmasi
            // Harga akhir dihitung otomatis dari billing_item_master (bukan input manual)

            // 3. Buat order
            $orderNumber = 'SM-' . date('Ymd') . '-' . strtoupper(Str::random(4));
            // Upload KTP & KK photos
            $ktpPath = $request->file('ktp_photo')->store('orders/documents', 's3');
            $kkPath = $request->file('kk_photo')->store('orders/documents', 's3');

            $order = Order::create([
                'order_number'    => $orderNumber,
                'pic_user_id'     => $request->user()->id,
                'so_user_id'      => $soUser?->id,
                'status'          => 'pending',
                'payment_status'  => 'unpaid',
                'pic_name'        => $request->pic_name,
                'pic_phone'       => $request->pic_phone,
                'pic_relation'    => $request->pic_relation,
                'pic_address'     => $request->pic_address,
                'deceased_name'   => $request->deceased_name,
                'deceased_dod'    => $request->deceased_dod,
                'deceased_religion' => $request->deceased_religion,
                'pickup_address'  => $request->pickup_address,
                'destination_address' => $request->destination_address,
                'funeral_home_id' => $request->funeral_home_id,
                'cemetery_id'     => $request->cemetery_id,
                'ktp_photo_path'  => $ktpPath,
                'kk_photo_path'   => $kkPath,
                'notes'           => $request->notes,
            ]);

            // 5. Buat ServiceAcceptanceLetter
            $letterNumber = 'SAL-' . now()->format('Ymd') . '-' . str_pad(
                \App\Models\ServiceAcceptanceLetter::whereDate('created_at', today())->count() + 1, 4, '0', STR_PAD_LEFT
            );
            $terms     = \App\Models\TermsAndConditions::current();
            $salStatus = ($soUser && $request->filled('officer_signature')) ? 'signed' : 'partial';

            \App\Models\ServiceAcceptanceLetter::create([
                'order_id'           => $order->id,
                'letter_number'      => $letterNumber,
                'status'             => $salStatus,
                'pj_nama'            => $request->pj_name,
                'pj_no_telp'         => $request->pic_phone,
                'pj_hubungan'        => $request->pic_relation,
                'pj_alamat'          => $request->pic_address,
                'almarhum_nama'      => $request->deceased_name,
                'almarhum_tgl_wafat' => $request->deceased_dod,
                'almarhum_agama'     => $request->deceased_religion,
                'terms_version'      => $terms?->version,
                'created_by'         => $request->user()->id,
                'pj_signature_path'  => $request->pj_signature,
                'pj_signed_at'       => now(),
                'sm_officer_id'      => $soUser?->id,
                'sm_officer_nama'    => $request->officer_name ?? $soUser?->name,
                'sm_signature_path'  => $request->officer_signature,
                'sm_signed_at'       => $request->filled('officer_signature') ? now() : null,
            ]);

            // 6. Status log
            OrderStatusLog::create([
                'order_id'  => $order->id,
                'user_id'   => $request->user()->id,
                'to_status' => 'pending',
                'notes'     => 'Order baru dari konsumen, menunggu SO memproses.' . ($soUser ? " SO terkait: {$soUser->name}." : ''),
            ]);

            // 7. Notifikasi — alarm ke semua SO + SO spesifik jika ada kode
            NotificationService::sendToRole(UserRole::SERVICE_OFFICER->value, 'ALARM',
                'Order Baru Masuk',
                "Order baru dari konsumen: {$order->order_number} ({$request->deceased_name}). Segera proses!",
                ['order_id' => $order->id]
            );
            if ($soUser) {
                NotificationService::send($soUser->id, 'ALARM',
                    'Order Baru — Konsumen Anda',
                    "Konsumen {$request->pic_name} membuat order baru: {$order->order_number}.",
                    ['order_id' => $order->id]
                );
            }

            // Gudang & Purchasing dapat akses lihat order pending (sesuai pedoman v1.13 Step 1)
            NotificationService::sendToRole(UserRole::GUDANG->value, 'HIGH',
                'Order Pending Baru',
                "Order {$order->order_number} masuk. Siap-siap stok setelah SO konfirmasi.",
                ['order_id' => $order->id]
            );

            return response()->json([
                'success'   => true,
                'data'      => $order->fresh(),
                'message'   => 'Order berhasil dibuat. Service Officer akan segera menghubungi Anda.',
                'so_linked' => $soUser ? ['id' => $soUser->id, 'name' => $soUser->name] : null,
            ], 201);
        });
    }

    public function index(Request $request)
    {
        $orders = Order::where('pic_user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $orders
        ]);
    }

    public function show($id, Request $request)
    {
        $storageService = app(\App\Services\StorageService::class);

        $order = Order::with(['driver', 'package', 'photos', 'orderAddOns'])
            ->where('pic_user_id', $request->user()->id)
            ->findOrFail($id);

        // Append URL to each photo
        $orderData = $order->toArray();
        $orderData['photos'] = collect($order->photos)->map(fn($photo) => array_merge(
            $photo->toArray(),
            ['url' => $storageService->getSignedUrl($photo->file_path)]
        ))->values()->toArray();

        return response()->json([
            'success' => true,
            'data' => $orderData
        ]);
    }
}
