<?php

use App\Enums\UserRole;
use App\Http\Controllers\Auth\AuthController;
use Illuminate\Support\Facades\Route;
use App\Models\User;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Version 1
|
*/

Route::prefix('v1')->middleware('throttle:api')->group(function () {


    Route::get('/health', [\App\Http\Controllers\SystemController::class, 'health']);

    // Config endpoint — frontend fetches all enums, thresholds, settings on startup
    // No hardcoded values in frontend — semua dari sini
    Route::get('/config', [\App\Http\Controllers\ConfigController::class, 'index']);
    Route::get('/config/thresholds', [\App\Http\Controllers\ConfigController::class, 'thresholds']);
    Route::get('/api-docs', [\App\Http\Controllers\ApiDocController::class, 'index']);

    // ── Public Endpoints (No Auth) — Landing Page, Blog, Berita Duka ─────
    Route::prefix('public')->group(function () {
        // Artikel / Blog
        Route::get('/articles', [\App\Http\Controllers\Public\PublicArticleController::class, 'index']);
        Route::get('/articles/categories', [\App\Http\Controllers\Public\PublicArticleController::class, 'categories']);
        Route::get('/articles/{slug}', [\App\Http\Controllers\Public\PublicArticleController::class, 'show']);

        // Berita Duka / Obituari
        Route::get('/obituaries', [\App\Http\Controllers\Public\PublicObituaryController::class, 'index']);
        Route::get('/obituaries/{slug}', [\App\Http\Controllers\Public\PublicObituaryController::class, 'show']);
    });

    Route::get('/test/fill-stock', function () {
        // Auto create stock for all package items in checklist to make testing easy
        $checklists = \App\Models\OrderChecklist::select('item_name', 'unit')->distinct()->get();
        foreach ($checklists as $c) {
            $stock = \App\Models\StockItem::where('item_name', $c->item_name)->first();
            if (!$stock) {
                \App\Models\StockItem::create([
                    'item_name' => $c->item_name,
                    'category' => 'Testing',
                    'current_quantity' => 5, // Set to 5 so it quickly drops to 0 and triggers PR
                    'minimum_quantity' => 3,
                    'unit' => $c->unit ?? 'pcs',
                ]);
            } else {
                $stock->update(['current_quantity' => 5]);
            }
        }
        return response()->json(['message' => 'Stock items initialized for testing.']);
    });

    // ── Auth (rate limited: 5 req/min to prevent brute force) ─────────────
    Route::prefix('auth')->middleware('throttle:auth')->group(function () {
        Route::post('/register-consumer', [AuthController::class, 'registerConsumer']);
        Route::post('/login-consumer',    [AuthController::class, 'loginConsumer']);
        Route::post('/login-internal',    [AuthController::class, 'loginInternal']);
        Route::post('/reset-pin',         [AuthController::class, 'resetPin']);
        Route::post('/login-biometric',   [AuthController::class, 'loginBiometric']);

        Route::middleware('auth:sanctum')->group(function () {
            Route::post('/logout',          [AuthController::class, 'logout']);
            Route::get('/me',               [AuthController::class, 'me']);
            Route::put('/fcm-token',        [AuthController::class, 'updateFcmToken']);
            Route::put('/update-password', [AuthController::class, 'updatePassword']);
        });
    });

    // ── Super Admin ───────────────────────────────────────────────────────────
    Route::middleware(['auth:sanctum', 'role:' . UserRole::SUPER_ADMIN->value])
        ->prefix('super-admin')
        ->group(function () {
            Route::get('/users',                      [\App\Http\Controllers\SuperAdmin\UserController::class, 'index']);
            Route::post('/users',                     [\App\Http\Controllers\SuperAdmin\UserController::class, 'store']);
            Route::get('/users/{id}',                 [\App\Http\Controllers\SuperAdmin\UserController::class, 'show']);
            Route::put('/users/{id}',                 [\App\Http\Controllers\SuperAdmin\UserController::class, 'update']);
            Route::put('/users/{id}/reset-password',  [\App\Http\Controllers\SuperAdmin\UserController::class, 'resetPassword']);
            Route::put('/users/{id}/deactivate',      [\App\Http\Controllers\SuperAdmin\UserController::class, 'deactivate']);
            Route::put('/users/{id}/activate',        [\App\Http\Controllers\SuperAdmin\UserController::class, 'activate']);
            Route::put('/users/{id}/verify-supplier', [\App\Http\Controllers\SuperAdmin\UserController::class, 'verifySupplier']);

            // Role management (dynamic roles)
            Route::get('/roles',                      [\App\Http\Controllers\SuperAdmin\RoleController::class, 'index']);
            Route::post('/roles',                     [\App\Http\Controllers\SuperAdmin\RoleController::class, 'store']);
            Route::put('/roles/{id}',                 [\App\Http\Controllers\SuperAdmin\RoleController::class, 'update']);
            Route::delete('/roles/{id}',              [\App\Http\Controllers\SuperAdmin\RoleController::class, 'destroy']);
            Route::get('/roles/{slug}/users',         [\App\Http\Controllers\SuperAdmin\RoleController::class, 'users']);
        });

    // ── Authenticated + non-viewer ────────────────────────────────────────────
    Route::middleware(['auth:sanctum', 'not_viewer'])->group(function () {

        // ── Shared Endpoints ───────────────────────────────────────────────
        Route::get('/addons', [\App\Http\Controllers\OrderAddOnController::class, 'index']);

        // ── Consumer ─────────────────────────────────────────────────────────
        Route::middleware('role:' . UserRole::CONSUMER->value)->prefix('consumer')->group(function () {
            Route::post('/orders',                                [\App\Http\Controllers\Consumer\OrderController::class, 'store']);
            Route::get('/orders',                                 [\App\Http\Controllers\Consumer\OrderController::class, 'index']);
            Route::get('/orders/{id}',                            [\App\Http\Controllers\Consumer\OrderController::class, 'show']);
            Route::post('/orders/{id}/photos',                    [\App\Http\Controllers\Consumer\PhotoController::class, 'store']);
            Route::delete('/orders/{id}/photos/{photoId}',        [\App\Http\Controllers\Consumer\PhotoController::class, 'destroy']);
            Route::post('/orders/{id}/addons',                    [\App\Http\Controllers\OrderAddOnController::class, 'store']);
            Route::get('/storage-quota',                          [\App\Http\Controllers\Consumer\PhotoController::class, 'getQuota']);
            Route::post('/ai/chat',                               [\App\Http\Controllers\AI\ChatController::class, 'chat']);
            Route::post('/ai/voice-to-text',                      [\App\Http\Controllers\AI\ChatController::class, 'voiceToText']);
            // v1.9 — Payment proof
            Route::post('/orders/{id}/payment-proof',             [\App\Http\Controllers\Consumer\PaymentProofController::class, 'store']);
            Route::get('/orders/{id}/payment-status',             [\App\Http\Controllers\Consumer\PaymentProofController::class, 'status']);
            // v1.13 — Gallery & Berita Duka (staff-uploaded docs)
            Route::get('/orders/{id}/gallery',                    [\App\Http\Controllers\Consumer\GalleryController::class,       'gallery']);
            Route::get('/orders/{id}/obituary',                   [\App\Http\Controllers\Consumer\GalleryController::class,       'obituary']);
            // v1.17 — Order acceptance / T&C signature
            Route::get('/orders/{id}/acceptance',                  [\App\Http\Controllers\Consumer\AcceptanceController::class,    'show']);
            Route::post('/orders/{id}/acceptance/sign',            [\App\Http\Controllers\Consumer\AcceptanceController::class,    'sign']);
            // Tukang Jaga item deliveries (keluarga konfirmasi)
            Route::get('/orders/{orderId}/deliveries',              [\App\Http\Controllers\Consumer\FamilyDeliveryController::class, 'index']);
            Route::post('/orders/{orderId}/deliveries/{deliveryId}/confirm', [\App\Http\Controllers\Consumer\FamilyDeliveryController::class, 'confirm']);
            // Invoice PDF (consumer — after order completed/paid)
            Route::get('/orders/{id}/invoice',                      [\App\Http\Controllers\InvoiceController::class, 'generatePdf']);
        });

        // ── Service Officer ───────────────────────────────────────────────────
        Route::middleware('role:' . UserRole::SERVICE_OFFICER->value)->prefix('so')->group(function () {
            Route::post('/orders',                   [\App\Http\Controllers\ServiceOfficer\OrderController::class,  'store']);
            Route::get('/orders',                    [\App\Http\Controllers\ServiceOfficer\OrderController::class,  'index']);
            Route::get('/orders/{id}',               [\App\Http\Controllers\ServiceOfficer\OrderController::class,  'show']);
            Route::delete('/orders/{id}',            [\App\Http\Controllers\ServiceOfficer\OrderController::class,  'destroy']);
            Route::put('/orders/{id}/submit',        [\App\Http\Controllers\ServiceOfficer\OrderController::class,  'submit']);
            // DEPRECATED v2.0 — confirm is now done atomically in store(). Kept to return helpful error to old clients.
            Route::put('/orders/{id}/confirm',       [\App\Http\Controllers\ServiceOfficer\OrderController::class,  'confirm']);
            Route::post('/orders/{id}/addons',       [\App\Http\Controllers\OrderAddOnController::class,            'store']);
            Route::get('/packages',                  [\App\Http\Controllers\ServiceOfficer\OrderController::class,  'packages']);
            Route::get('/ai/package-recommendation', [\App\Http\Controllers\AI\PackageRecommendationController::class, 'recommend']);
            // v1.10 — Walk-in order (SO kantor / SO lapangan)
            Route::post('/orders/walkin',            [\App\Http\Controllers\ServiceOfficer\WalkInController::class, 'store']);

            // CRM — Prospects, Visit Logs, Daily Report
            Route::get('/prospects',                 [\App\Http\Controllers\ServiceOfficer\CrmController::class, 'prospectIndex']);
            Route::post('/prospects',                [\App\Http\Controllers\ServiceOfficer\CrmController::class, 'prospectStore']);
            Route::put('/prospects/{id}',            [\App\Http\Controllers\ServiceOfficer\CrmController::class, 'prospectUpdate']);
            Route::get('/visits',                    [\App\Http\Controllers\ServiceOfficer\CrmController::class, 'visitLogIndex']);
            Route::post('/visits',                   [\App\Http\Controllers\ServiceOfficer\CrmController::class, 'visitLogStore']);
            Route::get('/daily-report',              [\App\Http\Controllers\ServiceOfficer\CrmController::class, 'dailyReport']);
        });

        // ── Admin ─────────────────────────────────────────────────────────────
        Route::middleware('role:' . implode(',', [UserRole::ADMIN->value, UserRole::OWNER->value]))
            ->prefix('admin')
            ->group(function () {
                Route::get('/dashboard',          [\App\Http\Controllers\Admin\DashboardController::class, 'index']);
                Route::get('/orders',             [\App\Http\Controllers\Admin\OrderController::class,     'index']);
                Route::get('/orders/{id}',        [\App\Http\Controllers\Admin\OrderController::class,     'show']);
                Route::put('/orders/{id}/approve',[\App\Http\Controllers\Admin\OrderController::class,     'approve']);
                Route::put('/orders/{id}/close',  [\App\Http\Controllers\Admin\OrderController::class,     'close']);
                Route::put('/orders/{id}/payment',[\App\Http\Controllers\Admin\OrderController::class,     'updatePayment']);
                Route::get('/drivers/available',  [\App\Http\Controllers\Admin\DashboardController::class, 'getAvailableDrivers']);
                Route::get('/vehicles/available', [\App\Http\Controllers\Admin\DashboardController::class, 'getAvailableVehicles']);

                // ── Armada (Mobil Jenazah) ─────────────────────────────────
                Route::get('/vehicles',                   [\App\Http\Controllers\Admin\VehicleController::class,  'index']);
                Route::post('/vehicles',                  [\App\Http\Controllers\Admin\VehicleController::class,  'store']);
                Route::get('/vehicles/{id}',              [\App\Http\Controllers\Admin\VehicleController::class,  'show']);
                Route::put('/vehicles/{id}',              [\App\Http\Controllers\Admin\VehicleController::class,  'update']);
                Route::delete('/vehicles/{id}',           [\App\Http\Controllers\Admin\VehicleController::class,  'destroy']);

                // ── CRM Dokumentasi Pasca Acara ───────────────────────────
                Route::get('/documentation/orders',                   [\App\Http\Controllers\Admin\DocumentationController::class, 'orders']);
                Route::get('/documentation/orders/{id}',              [\App\Http\Controllers\Admin\DocumentationController::class, 'show']);
                Route::post('/documentation/orders/{id}/photos',      [\App\Http\Controllers\Admin\DocumentationController::class, 'uploadPhotos']);
                Route::post('/documentation/orders/{id}/drive-link',  [\App\Http\Controllers\Admin\DocumentationController::class, 'attachDriveLink']);
                Route::delete('/documentation/photos/{photoId}',      [\App\Http\Controllers\Admin\DocumentationController::class, 'deletePhoto']);

                // ── Manajemen Paket — GET: admin + owner, write: admin only ──
                Route::get('/packages',                       [\App\Http\Controllers\Admin\PackageController::class, 'index']);
                Route::get('/packages/{id}',                  [\App\Http\Controllers\Admin\PackageController::class, 'show']);
                Route::get('/stock-items',                    [\App\Http\Controllers\Admin\PackageController::class, 'stockItems']);
                Route::get('/provider-roles',                 [\App\Http\Controllers\Admin\PackageController::class, 'providerRoles']);

                // ── Artikel / Blog ───────────────────────────────────────
                Route::get('/articles',                  [\App\Http\Controllers\Admin\ArticleController::class,   'index']);
                Route::post('/articles',                 [\App\Http\Controllers\Admin\ArticleController::class,   'store']);
                Route::get('/articles/{id}',             [\App\Http\Controllers\Admin\ArticleController::class,   'show']);
                Route::put('/articles/{id}',             [\App\Http\Controllers\Admin\ArticleController::class,   'update']);
                Route::post('/articles/{id}/cover',      [\App\Http\Controllers\Admin\ArticleController::class,   'uploadCover']);
                Route::delete('/articles/{id}',          [\App\Http\Controllers\Admin\ArticleController::class,   'destroy']);

                // ── Berita Duka / Obituari ────────────────────────────────
                Route::get('/obituaries',                    [\App\Http\Controllers\Admin\ObituaryController::class, 'index']);
                Route::post('/obituaries',                   [\App\Http\Controllers\Admin\ObituaryController::class, 'store']);
                Route::get('/obituaries/{id}',               [\App\Http\Controllers\Admin\ObituaryController::class, 'show']);
                Route::put('/obituaries/{id}',               [\App\Http\Controllers\Admin\ObituaryController::class, 'update']);
                Route::post('/obituaries/{id}/photo',        [\App\Http\Controllers\Admin\ObituaryController::class, 'uploadPhoto']);
                Route::post('/obituaries/from-order/{orderId}', [\App\Http\Controllers\Admin\ObituaryController::class, 'createFromOrder']);
                Route::delete('/obituaries/{id}',            [\App\Http\Controllers\Admin\ObituaryController::class, 'destroy']);

                // Tukang jaga management
                Route::get('/tukang-jaga/wage-configs',            [\App\Http\Controllers\Admin\TukangJagaManagementController::class, 'wageConfigs']);
                Route::post('/tukang-jaga/wage-configs',           [\App\Http\Controllers\Admin\TukangJagaManagementController::class, 'storeWageConfig']);
                Route::put('/tukang-jaga/wage-configs/{id}',       [\App\Http\Controllers\Admin\TukangJagaManagementController::class, 'updateWageConfig']);
                Route::get('/orders/{orderId}/shifts',             [\App\Http\Controllers\Admin\TukangJagaManagementController::class, 'orderShifts']);
                Route::post('/orders/{orderId}/shifts/generate',   [\App\Http\Controllers\Admin\TukangJagaManagementController::class, 'generateShifts']);
                Route::put('/shifts/{id}/assign',                  [\App\Http\Controllers\Admin\TukangJagaManagementController::class, 'assignShift']);

                // v1.31 — Funeral Homes & Cemeteries (admin CRUD, index/show are public within auth)
                Route::apiResource('funeral-homes', \App\Http\Controllers\Admin\FuneralHomeController::class)->except(['index', 'show']);
                Route::apiResource('cemeteries', \App\Http\Controllers\Admin\CemeteryController::class)->except(['index', 'show']);
            });

        // ── Package write routes — admin only (owner excluded) ────────────────
        Route::middleware(['auth:sanctum', 'role:' . UserRole::ADMIN->value])
            ->prefix('admin')
            ->group(function () {
                Route::post('/packages',                      [\App\Http\Controllers\Admin\PackageController::class, 'store']);
                Route::put('/packages/{id}',                  [\App\Http\Controllers\Admin\PackageController::class, 'update']);
                Route::delete('/packages/{id}',               [\App\Http\Controllers\Admin\PackageController::class, 'destroy']);
                Route::post('/packages/{id}/items',           [\App\Http\Controllers\Admin\PackageController::class, 'addItem']);
                Route::put('/packages/{id}/items/{itemId}',   [\App\Http\Controllers\Admin\PackageController::class, 'updateItem']);
                Route::delete('/packages/{id}/items/{itemId}',[\App\Http\Controllers\Admin\PackageController::class, 'removeItem']);
            });

        // ── Gudang ────────────────────────────────────────────────────────────
        Route::middleware('role:' . UserRole::GUDANG->value)->prefix('gudang')->group(function () {
            Route::get('/purchase-orders',              [\App\Http\Controllers\Gudang\PurchaseOrderController::class, 'index']);
            Route::post('/purchase-orders',             [\App\Http\Controllers\Gudang\PurchaseOrderController::class, 'store']);
            Route::get('/purchase-orders/{id}',         [\App\Http\Controllers\Gudang\PurchaseOrderController::class, 'show']);
            Route::put('/purchase-orders/{id}/complete',[\App\Http\Controllers\Gudang\PurchaseOrderController::class, 'complete']);
            Route::get('/stock',                        [\App\Http\Controllers\Gudang\StockController::class,         'index']);
            Route::post('/stock',                       [\App\Http\Controllers\Gudang\StockController::class,         'store']);
            Route::put('/stock/{id}',                   [\App\Http\Controllers\Gudang\StockController::class,         'update']);
            Route::put('/supplier-quotes/{id}/accept',  [\App\Http\Controllers\Vendor\SupplierQuoteController::class, 'accept']);
            Route::put('/supplier-quotes/{id}/reject',  [\App\Http\Controllers\Vendor\SupplierQuoteController::class, 'reject']);

            // v1.9 — Orders list + Stock Ready Gate (order checklist)
            Route::get('/orders',                            [\App\Http\Controllers\Gudang\OrderController::class,         'index']);
            Route::get('/orders/{id}/checklist',             [\App\Http\Controllers\Gudang\OrderStockController::class,    'checklist']);
            Route::put('/orders/{id}/checklist/{itemId}',    [\App\Http\Controllers\Gudang\OrderStockController::class,    'checkItem']);
            Route::put('/orders/{id}/stock-ready',           [\App\Http\Controllers\Gudang\OrderStockController::class,    'stockReady']);

            // v1.11 — e-Katalog (Procurement)
            Route::get('/procurement-requests',              [\App\Http\Controllers\Gudang\ProcurementController::class,   'index']);
            Route::post('/procurement-requests',             [\App\Http\Controllers\Gudang\ProcurementController::class,   'store']);
            Route::get('/procurement-requests/{id}',         [\App\Http\Controllers\Gudang\ProcurementController::class,   'show']);
            Route::put('/procurement-requests/{id}/publish', [\App\Http\Controllers\Gudang\ProcurementController::class,   'publish']);
            Route::put('/procurement-requests/{id}/cancel',  [\App\Http\Controllers\Gudang\ProcurementController::class,   'cancel']);
            Route::get('/procurement-requests/{id}/quotes',  [\App\Http\Controllers\Gudang\ProcurementController::class,   'quotes']);
            Route::put('/procurement-requests/{id}/receive', [\App\Http\Controllers\Gudang\ProcurementController::class,   'receive']);
            Route::put('/procurement-quotes/{quoteId}/award', [\App\Http\Controllers\Gudang\ProcurementController::class,  'awardQuote']);
            Route::put('/procurement-quotes/{quoteId}/reject',[\App\Http\Controllers\Gudang\ProcurementController::class,  'rejectQuote']);
            Route::post('/supplier-ratings',                  [\App\Http\Controllers\Gudang\ProcurementController::class,  'rateSupplier']);
        });

        // ── Role Stock — akses generik untuk semua role internal yang punya inventaris ─
        Route::middleware(['auth:sanctum'])->prefix('role-stock')->group(function () {
            Route::get('/items',                             [\App\Http\Controllers\RoleStock\RoleStockController::class, 'index']);
            Route::post('/items',                            [\App\Http\Controllers\RoleStock\RoleStockController::class, 'store']);
            Route::put('/items/{id}',                        [\App\Http\Controllers\RoleStock\RoleStockController::class, 'update']);
            Route::delete('/items/{id}',                     [\App\Http\Controllers\RoleStock\RoleStockController::class, 'destroy']);
            Route::get('/orders/{orderId}/checklist',         [\App\Http\Controllers\RoleStock\RoleStockController::class, 'orderChecklist']);
            Route::put('/checklist/{id}/check',              [\App\Http\Controllers\RoleStock\RoleStockController::class, 'checkItem']);
            Route::put('/checklist/{id}/uncheck',            [\App\Http\Controllers\RoleStock\RoleStockController::class, 'uncheckItem']);
        });

        // ── Finance ───────────────────────────────────────────────────────────
        Route::middleware('role:' . implode(',', [UserRole::FINANCE->value, UserRole::PURCHASING->value]))->prefix('finance')->group(function () {
            Route::get('/purchase-orders',             [\App\Http\Controllers\Finance\PurchaseOrderController::class,         'index']);
            Route::get('/purchase-orders/{id}',        [\App\Http\Controllers\Finance\PurchaseOrderController::class,         'show']);
            Route::put('/purchase-orders/{id}/approve',[\App\Http\Controllers\Finance\PurchaseOrderController::class,         'approve']);
            Route::put('/purchase-orders/{id}/reject', [\App\Http\Controllers\Finance\PurchaseOrderController::class,         'reject']);

            // v1.9 — Consumer payment verification
            Route::get('/orders',                      [\App\Http\Controllers\Finance\ConsumerPaymentController::class,       'index']);
            Route::get('/orders/{id}',                 [\App\Http\Controllers\Finance\ConsumerPaymentController::class,       'show']);
            Route::get('/orders/{id}/payment-proof',   [\App\Http\Controllers\Finance\ConsumerPaymentController::class,       'getPaymentProof']);
            Route::put('/orders/{id}/payment/verify',  [\App\Http\Controllers\Finance\ConsumerPaymentController::class,       'verify']);
            Route::put('/orders/{id}/payment/reject',  [\App\Http\Controllers\Finance\ConsumerPaymentController::class,       'reject']);
            Route::post('/orders/{id}/cash-paid',      [\App\Http\Controllers\Finance\ConsumerPaymentController::class,       'markCashPaid']);

            // v1.10 — Field team payments
            Route::get('/orders/{id}/field-team',      [\App\Http\Controllers\Finance\FieldTeamController::class,             'index']);
            Route::post('/orders/{id}/field-team',     [\App\Http\Controllers\Finance\FieldTeamController::class,             'store']);
            Route::put('/field-team/{memberId}/pay',   [\App\Http\Controllers\Finance\FieldTeamController::class,             'pay']);
            Route::delete('/field-team/{memberId}',    [\App\Http\Controllers\Finance\FieldTeamController::class,             'destroy']);
            Route::get('/field-team/pending',          [\App\Http\Controllers\Finance\FieldTeamController::class,             'pending']);

            // v1.11 — e-Katalog procurement approval
            Route::get('/procurement-requests',                    [\App\Http\Controllers\Finance\ProcurementApprovalController::class, 'index']);
            Route::get('/procurement-requests/{id}',               [\App\Http\Controllers\Finance\ProcurementApprovalController::class, 'show']);
            Route::put('/procurement-requests/{id}/approve',       [\App\Http\Controllers\Finance\ProcurementApprovalController::class, 'approve']);
            Route::put('/procurement-requests/{id}/reject',        [\App\Http\Controllers\Finance\ProcurementApprovalController::class, 'reject']);

            // v1.11 — Supplier transactions (bayar supplier)
            Route::get('/supplier-transactions',                   [\App\Http\Controllers\Finance\SupplierTransactionController::class,  'index']);
            Route::get('/supplier-transactions/summary',           [\App\Http\Controllers\Finance\SupplierTransactionController::class,  'summary']);
            Route::get('/supplier-transactions/{id}',              [\App\Http\Controllers\Finance\SupplierTransactionController::class,  'show']);
            Route::put('/supplier-transactions/{id}/pay',          [\App\Http\Controllers\Finance\SupplierTransactionController::class,  'pay']);

            // v1.30 — Laporan Keuangan (Finance + Owner)
            Route::get('/dashboard',                               [\App\Http\Controllers\Finance\FinanceDashboardController::class,     'index']);
            Route::get('/reports/summary',                         [\App\Http\Controllers\Finance\FinanceReportController::class,        'summary']);
            Route::get('/reports/orders',                          [\App\Http\Controllers\Finance\FinanceReportController::class,        'orders']);
            Route::get('/reports/receivables',                     [\App\Http\Controllers\Finance\FinanceReportController::class,        'receivables']);
            Route::get('/reports/expenses',                        [\App\Http\Controllers\Finance\FinanceReportController::class,        'expenses']);
            Route::get('/reports/export',                          [\App\Http\Controllers\Finance\FinanceReportController::class,        'export']);
            Route::get('/transactions',                            [\App\Http\Controllers\Finance\FinanceTransactionController::class,   'index']);
            Route::post('/transactions/correction',                [\App\Http\Controllers\Finance\FinanceTransactionController::class,   'correction']);
            Route::put('/transactions/{id}/void',                  [\App\Http\Controllers\Finance\FinanceTransactionController::class,   'void']);
            // Invoice PDF per order
            Route::get('/orders/{orderId}/invoice-pdf',            [\App\Http\Controllers\InvoiceController::class,                      'generatePdf']);
        });

        // ── Driver ────────────────────────────────────────────────────────────
        Route::middleware('role:' . UserRole::DRIVER->value)->prefix('driver')->group(function () {
            Route::get('/orders',              [\App\Http\Controllers\Driver\OrderController::class,  'index']);
            Route::get('/orders/{id}',         [\App\Http\Controllers\Driver\OrderController::class,  'show']);
            Route::put('/orders/{id}/status',  [\App\Http\Controllers\Driver\OrderController::class,  'updateStatus']);
            Route::put('/orders/{id}/transition', [\App\Http\Controllers\Driver\OrderController::class, 'transition']);
            Route::post('/location',           [\App\Http\Controllers\Driver\LocationController::class,'store']);
            // v1.17 — GPS real-time tracking (10s interval)
            Route::post('/gps',                [\App\Http\Controllers\Driver\GpsTrackingController::class, 'updateLocation']);
            // Driver session (On Duty)
            Route::post('/session/start',      [\App\Http\Controllers\Driver\SessionController::class, 'start']);
            Route::post('/session/end',        [\App\Http\Controllers\Driver\SessionController::class, 'end']);
            Route::get('/session/active',      [\App\Http\Controllers\Driver\SessionController::class, 'active']);
            // v1.9 — Bukti lapangan
            Route::post('/orders/{id}/bukti',  [\App\Http\Controllers\Driver\BuktiController::class,   'store']);
            Route::get('/orders/{id}/bukti',   [\App\Http\Controllers\Driver\BuktiController::class,   'index']);
            Route::post('/orders/{orderId}/deliver-to-jaga', [\App\Http\Controllers\Driver\TukangJagaDeliveryController::class, 'deliver']);
            // v1.20 — Vehicle management (KM, fuel, inspection, maintenance)
            Route::post('/vehicles/{vehicleId}/km-log',       [\App\Http\Controllers\Driver\VehicleManagementController::class, 'storeKmLog']);
            Route::get('/vehicles/{vehicleId}/km-logs',       [\App\Http\Controllers\Driver\VehicleManagementController::class, 'getKmLogs']);
            Route::post('/vehicles/{vehicleId}/fuel-logs',    [\App\Http\Controllers\Driver\VehicleManagementController::class, 'storeFuelLog']);
            Route::get('/vehicles/{vehicleId}/fuel-logs',     [\App\Http\Controllers\Driver\VehicleManagementController::class, 'getFuelLogs']);
            Route::post('/vehicles/{vehicleId}/inspections',  [\App\Http\Controllers\Driver\VehicleManagementController::class, 'storeInspection']);
            Route::post('/vehicles/{vehicleId}/maintenance-requests', [\App\Http\Controllers\Driver\VehicleManagementController::class, 'storeMaintenanceRequest']);
            Route::get('/maintenance-requests',               [\App\Http\Controllers\Driver\VehicleManagementController::class, 'getMyMaintenanceRequests']);
        });

        // ── Vendor (dekor, konsumsi, pemuka_agama) ────────────────────────────
        Route::middleware('role:' . implode(',', [UserRole::DEKOR->value, UserRole::KONSUMSI->value, UserRole::PEMUKA_AGAMA->value ?? 'pemuka_agama']))
            ->prefix('vendor')
            ->group(function () {
                Route::get('/assignments',              [\App\Http\Controllers\Vendor\AssignmentController::class,    'index']);
                Route::get('/assignments/{id}',         [\App\Http\Controllers\Vendor\AssignmentController::class,    'show']);
                Route::put('/assignments/{id}/confirm', [\App\Http\Controllers\Vendor\AssignmentController::class,    'confirm']);
                Route::put('/assignments/{id}/reject',  [\App\Http\Controllers\Vendor\AssignmentController::class,    'reject']);
                Route::put('/assignments/{id}/done',    [\App\Http\Controllers\Vendor\AssignmentController::class,    'done']);
                // v1.9 — Bukti lapangan
                Route::post('/assignments/{id}/bukti',  [\App\Http\Controllers\Vendor\BuktiController::class,         'store']);
            });

        // ── Supplier ──────────────────────────────────────────────────────────
        Route::middleware('role:' . UserRole::SUPPLIER->value)->prefix('supplier')->group(function () {
            // Old PO-based system (legacy)
            Route::get('/purchase-orders',                [\App\Http\Controllers\Vendor\PurchaseOrderController::class,  'index']);
            Route::get('/purchase-orders/{id}',           [\App\Http\Controllers\Vendor\PurchaseOrderController::class,  'show']);
            Route::get('/legacy-quotes',                  [\App\Http\Controllers\Vendor\SupplierQuoteController::class,  'index']);
            Route::post('/legacy-quotes',                 [\App\Http\Controllers\Vendor\SupplierQuoteController::class,  'store']);
            Route::get('/legacy-quotes/{id}',             [\App\Http\Controllers\Vendor\SupplierQuoteController::class,  'show']);
            Route::post('/legacy-quotes/{id}/photo',      [\App\Http\Controllers\Vendor\SupplierQuoteController::class,  'uploadPhoto']);
            Route::put('/legacy-quotes/{id}/cancel',      [\App\Http\Controllers\Vendor\SupplierQuoteController::class,  'cancel']);

            // v1.11 — e-Katalog: lihat permintaan pengadaan
            Route::get('/procurement-requests',           [\App\Http\Controllers\Supplier\CatalogController::class,     'index']);
            Route::get('/procurement-requests/{id}',      [\App\Http\Controllers\Supplier\CatalogController::class,     'show']);

            // v1.11 — e-Katalog: kelola penawaran
            Route::post('/quotes',                        [\App\Http\Controllers\Supplier\QuoteController::class,       'store']);
            Route::get('/quotes',                         [\App\Http\Controllers\Supplier\QuoteController::class,       'index']);
            Route::get('/quotes/{id}',                    [\App\Http\Controllers\Supplier\QuoteController::class,       'show']);
            Route::put('/quotes/{id}/cancel',             [\App\Http\Controllers\Supplier\QuoteController::class,       'cancel']);
            Route::post('/quotes/{id}/product-photo',     [\App\Http\Controllers\Supplier\QuoteController::class,       'uploadPhoto']);

            // v1.11 — Setelah menang: kirim barang & transaksi
            Route::put('/quotes/{id}/mark-shipped',       [\App\Http\Controllers\Supplier\TransactionController::class, 'markShipped']);
            Route::get('/transactions',                   [\App\Http\Controllers\Supplier\TransactionController::class, 'index']);
            Route::get('/transactions/{id}',              [\App\Http\Controllers\Supplier\TransactionController::class, 'show']);
            Route::put('/transactions/{id}/confirm-payment', [\App\Http\Controllers\Supplier\TransactionController::class, 'confirmPayment']);

            // Profil & statistik
            Route::get('/profile',                        [\App\Http\Controllers\Supplier\TransactionController::class, 'profile']);
            Route::put('/profile',                        [\App\Http\Controllers\Supplier\TransactionController::class, 'updateProfile']);
            Route::get('/ratings',                        [\App\Http\Controllers\Supplier\TransactionController::class, 'ratings']);
            Route::get('/stats',                          [\App\Http\Controllers\Supplier\TransactionController::class, 'stats']);
        });

        // ── Owner — view-only, anomaly override only ──────────────────────────
        Route::middleware('role:' . UserRole::OWNER->value)->prefix('owner')->group(function () {
            Route::get('/dashboard',                      [\App\Http\Controllers\Owner\DashboardController::class,      'index']);
            Route::get('/orders',                         [\App\Http\Controllers\Owner\DashboardController::class,      'orders']);
            Route::get('/reports/daily',                  [\App\Http\Controllers\Owner\DashboardController::class,      'reports']);
            Route::get('/purchase-orders/anomalies',      [\App\Http\Controllers\Owner\PurchaseOrderController::class,  'anomalies']);
            Route::put('/purchase-orders/{id}/override',  [\App\Http\Controllers\Owner\PurchaseOrderController::class,  'override']);
            // v1.10 — HRD violations & thresholds
            Route::get('/hrd/violations',                 [\App\Http\Controllers\Owner\ViolationController::class,      'index']);
            Route::put('/thresholds/{key}',               [\App\Http\Controllers\Owner\ViolationController::class,      'updateThreshold']);
            // v1.35 — Employee location tracking
            Route::get('/employee-locations',             [\App\Http\Controllers\UserLocationController::class,         'allEmployeeLocations']);
            Route::get('/employee-locations/{userId}/history', [\App\Http\Controllers\UserLocationController::class,    'employeeLocationHistory']);
            // v1.36 — Owner Commands
            Route::get('/commands',                       [\App\Http\Controllers\Owner\CommandController::class,        'index']);
            Route::post('/commands',                      [\App\Http\Controllers\Owner\CommandController::class,        'store']);
            Route::get('/commands/{id}',                  [\App\Http\Controllers\Owner\CommandController::class,        'show']);
            Route::delete('/commands/{id}',               [\App\Http\Controllers\Owner\CommandController::class,        'cancel']);
        });

        // ── HRD ───────────────────────────────────────────────────────────────
        Route::middleware('role:' . UserRole::HRD->value)->prefix('hrd')->group(function () {
            Route::get('/violations',                     [\App\Http\Controllers\HRD\ViolationController::class,        'index']);
            Route::get('/violations/monthly-report',      [\App\Http\Controllers\HRD\ViolationController::class,        'monthlyReport']);
            Route::get('/violations/by-user/{userId}',    [\App\Http\Controllers\HRD\ViolationController::class,        'byUser']);
            Route::get('/violations/{id}',                [\App\Http\Controllers\HRD\ViolationController::class,        'show']);
            Route::put('/violations/{id}/acknowledge',    [\App\Http\Controllers\HRD\ViolationController::class,        'acknowledge']);
            Route::put('/violations/{id}/resolve',        [\App\Http\Controllers\HRD\ViolationController::class,        'resolve']);
            Route::put('/violations/{id}/escalate',       [\App\Http\Controllers\HRD\ViolationController::class,        'escalate']);
            Route::get('/thresholds',                     [\App\Http\Controllers\HRD\ThresholdController::class,        'index']);
            Route::put('/thresholds/{key}',               [\App\Http\Controllers\HRD\ThresholdController::class,        'update']);
            // v1.14 — Attendances
            Route::get('/attendances',                    [\App\Http\Controllers\HRD\AttendanceController::class,       'index']);
            // v1.35 — Employee management (HR bisa buat & kelola akun karyawan)
            Route::get('/employees',                      [\App\Http\Controllers\HRD\EmployeeController::class,         'index']);
            Route::post('/employees',                     [\App\Http\Controllers\HRD\EmployeeController::class,         'store']);
            Route::get('/employees/{id}',                 [\App\Http\Controllers\HRD\EmployeeController::class,         'show']);
            Route::put('/employees/{id}',                 [\App\Http\Controllers\HRD\EmployeeController::class,         'update']);
            Route::put('/employees/{id}/reset-password',  [\App\Http\Controllers\HRD\EmployeeController::class,         'resetPassword']);
            Route::put('/employees/{id}/deactivate',      [\App\Http\Controllers\HRD\EmployeeController::class,         'deactivate']);
            Route::put('/employees/{id}/activate',        [\App\Http\Controllers\HRD\EmployeeController::class,         'activate']);
            // v1.16 — KPI
            Route::get('/kpi/metrics',                    [\App\Http\Controllers\KPI\KpiController::class,              'metricsIndex']);
            Route::post('/kpi/metrics',                   [\App\Http\Controllers\KPI\KpiController::class,              'metricsStore']);
            Route::put('/kpi/metrics/{id}',               [\App\Http\Controllers\KPI\KpiController::class,              'metricsUpdate']);
            Route::get('/kpi/periods',                    [\App\Http\Controllers\KPI\KpiController::class,              'periodsIndex']);
            Route::post('/kpi/periods',                   [\App\Http\Controllers\KPI\KpiController::class,              'periodsStore']);
            Route::get('/kpi/periods/{periodId}/scores',  [\App\Http\Controllers\KPI\KpiController::class,              'scores']);
            Route::get('/kpi/periods/{periodId}/summaries', [\App\Http\Controllers\KPI\KpiController::class,            'summaries']);
            Route::get('/kpi/periods/{periodId}/rankings', [\App\Http\Controllers\KPI\KpiController::class,             'rankings']);
            // Payroll
            Route::get('/salaries',                       [\App\Http\Controllers\HRD\PayrollController::class,          'salaryIndex']);
            Route::post('/salaries',                      [\App\Http\Controllers\HRD\PayrollController::class,          'salaryStore']);
            Route::put('/salaries/{id}',                  [\App\Http\Controllers\HRD\PayrollController::class,          'salaryUpdate']);
            Route::get('/payroll',                        [\App\Http\Controllers\HRD\PayrollController::class,          'payrollIndex']);
            Route::post('/payroll/generate',              [\App\Http\Controllers\HRD\PayrollController::class,          'payrollGenerate']);
            Route::put('/payroll/{id}/approve',           [\App\Http\Controllers\HRD\PayrollController::class,          'payrollApprove']);
            Route::get('/payroll/export',                 [\App\Http\Controllers\HRD\PayrollController::class,          'payrollExport']);
        });

        // ── v1.14 — Workshop Peti (Gudang) ───────────────────────────────────
        Route::middleware('role:' . UserRole::GUDANG->value)->prefix('gudang')->group(function () {
            // Coffin Orders
            Route::post('/coffin-orders',                         [\App\Http\Controllers\Gudang\CoffinOrderController::class,  'store']);
            Route::get('/coffin-orders',                          [\App\Http\Controllers\Gudang\CoffinOrderController::class,  'index']);
            Route::get('/coffin-orders/{id}',                     [\App\Http\Controllers\Gudang\CoffinOrderController::class,  'show']);
            Route::put('/coffin-orders/{id}/status',              [\App\Http\Controllers\Gudang\CoffinOrderController::class,  'updateStatus']);
            Route::put('/coffin-orders/{id}/stages/{stageId}',    [\App\Http\Controllers\Gudang\CoffinOrderController::class,  'completeStage']);
            Route::post('/coffin-orders/{id}/qc',                 [\App\Http\Controllers\Gudang\CoffinOrderController::class,  'submitQc']);
            // Equipment Master
            Route::get('/equipment-master',                       [\App\Http\Controllers\Gudang\EquipmentController::class,    'masterIndex']);
            // Order Equipment
            Route::get('/orders/{orderId}/equipment',             [\App\Http\Controllers\Gudang\EquipmentController::class,    'orderEquipmentIndex']);
            Route::post('/orders/{orderId}/equipment',            [\App\Http\Controllers\Gudang\EquipmentController::class,    'prepareOrderEquipment']);
            Route::put('/orders/{orderId}/equipment/{itemId}/send', [\App\Http\Controllers\Gudang\EquipmentController::class,  'sendItem']);
            Route::put('/orders/{orderId}/equipment/{itemId}/return', [\App\Http\Controllers\Gudang\EquipmentController::class, 'returnItem']);
            Route::get('/equipment/missing',                      [\App\Http\Controllers\Gudang\EquipmentController::class,    'missingEquipment']);
            // Equipment Loans
            Route::post('/equipment-loans',                       [\App\Http\Controllers\Gudang\EquipmentController::class,    'loanStore']);
            Route::get('/equipment-loans',                        [\App\Http\Controllers\Gudang\EquipmentController::class,    'loanIndex']);
            Route::get('/equipment-loans/{id}',                   [\App\Http\Controllers\Gudang\EquipmentController::class,    'loanShow']);
            Route::put('/equipment-loans/{id}/status',            [\App\Http\Controllers\Gudang\EquipmentController::class,    'loanUpdateStatus']);
            // Stock Alerts
            Route::get('/stock-alerts',                           [\App\Http\Controllers\Gudang\StockAlertController::class,   'index']);
            Route::put('/stock-alerts/{id}/resolve',              [\App\Http\Controllers\Gudang\StockAlertController::class,   'resolve']);
            // Consumables summary
            Route::get('/consumables/summary',                    [\App\Http\Controllers\ConsumableController::class,          'index']);
            // Vehicle trip logs (Gudang view)
            Route::get('/vehicle-trip-logs',                      [\App\Http\Controllers\Driver\VehicleTripLogController::class, 'index']);
            // Stock form (pengambilan/pengembalian)
            Route::post('/stock/form',                            [\App\Http\Controllers\Gudang\StockFormController::class,      'submitForm']);
            Route::get('/stock/deductions',                       [\App\Http\Controllers\Gudang\StockFormController::class,      'deductions']);
            // v1.20 — Vehicle maintenance & fuel validation
            Route::get('/maintenance-requests',                   [\App\Http\Controllers\Gudang\VehicleMaintenanceController::class, 'index']);
            Route::get('/maintenance-requests/{id}',              [\App\Http\Controllers\Gudang\VehicleMaintenanceController::class, 'show']);
            Route::put('/maintenance-requests/{id}/acknowledge',  [\App\Http\Controllers\Gudang\VehicleMaintenanceController::class, 'acknowledge']);
            Route::put('/maintenance-requests/{id}/start',        [\App\Http\Controllers\Gudang\VehicleMaintenanceController::class, 'start']);
            Route::put('/maintenance-requests/{id}/complete',     [\App\Http\Controllers\Gudang\VehicleMaintenanceController::class, 'complete']);
            Route::put('/maintenance-requests/{id}/defer',        [\App\Http\Controllers\Gudang\VehicleMaintenanceController::class, 'defer']);
            Route::get('/fuel-logs',                              [\App\Http\Controllers\Gudang\VehicleMaintenanceController::class, 'fuelLogs']);
            Route::put('/fuel-logs/{id}/validate',                [\App\Http\Controllers\Gudang\VehicleMaintenanceController::class, 'validateFuel']);
            Route::put('/fuel-logs/{id}/reject',                  [\App\Http\Controllers\Gudang\VehicleMaintenanceController::class, 'rejectFuel']);
        });

        // ── v1.14 — SO extras ─────────────────────────────────────────────────
        Route::middleware('role:' . UserRole::SERVICE_OFFICER->value)->prefix('so')->group(function () {
            // Attendance confirm
            Route::put('/attendances/{id}/confirm',               [\App\Http\Controllers\ServiceOfficer\AttendanceController::class, 'confirm']);
            // Death Certificate
            Route::post('/orders/{orderId}/death-cert-docs',      [\App\Http\Controllers\ServiceOfficer\DeathCertController::class,  'store']);
            Route::get('/orders/{orderId}/death-cert-docs',       [\App\Http\Controllers\ServiceOfficer\DeathCertController::class,  'show']);
            Route::put('/orders/{orderId}/death-cert-docs',       [\App\Http\Controllers\ServiceOfficer\DeathCertController::class,  'update']);
            // Extra Approvals
            Route::post('/orders/{orderId}/extra-approvals',      [\App\Http\Controllers\ServiceOfficer\ExtraApprovalController::class, 'store']);
            Route::get('/orders/{orderId}/extra-approvals',       [\App\Http\Controllers\ServiceOfficer\ExtraApprovalController::class, 'index']);
            Route::put('/orders/{orderId}/extra-approvals/{id}',  [\App\Http\Controllers\ServiceOfficer\ExtraApprovalController::class, 'update']);
            Route::post('/orders/{orderId}/extra-approvals/{id}/sign', [\App\Http\Controllers\ServiceOfficer\ExtraApprovalController::class, 'sign']);
            // Billing (SO add manual)
            Route::post('/orders/{orderId}/billing-items',        [\App\Http\Controllers\BillingController::class,                     'storeManual']);
            // Stock check preview (before confirm)
            Route::get('/orders/{orderId}/stock-check',           [\App\Http\Controllers\ServiceOfficer\StockCheckController::class,   'preview']);
            // v1.25 — Service Acceptance Letter
            Route::post('/orders/{orderId}/acceptance-letter',    [\App\Http\Controllers\ServiceOfficer\AcceptanceLetterController::class, 'store']);
            Route::get('/orders/{orderId}/acceptance-letter',     [\App\Http\Controllers\ServiceOfficer\AcceptanceLetterController::class, 'show']);
            Route::put('/orders/{orderId}/acceptance-letter',     [\App\Http\Controllers\ServiceOfficer\AcceptanceLetterController::class, 'update']);
            Route::post('/orders/{orderId}/acceptance-letter/sign-pj',   [\App\Http\Controllers\ServiceOfficer\AcceptanceLetterController::class, 'signPj']);
            Route::post('/orders/{orderId}/acceptance-letter/sign-sm',   [\App\Http\Controllers\ServiceOfficer\AcceptanceLetterController::class, 'signSm']);
            Route::post('/orders/{orderId}/acceptance-letter/sign-saksi', [\App\Http\Controllers\ServiceOfficer\AcceptanceLetterController::class, 'signSaksi']);
            Route::get('/orders/{orderId}/acceptance-letter/pdf', [\App\Http\Controllers\ServiceOfficer\AcceptanceLetterController::class, 'exportPdf']);
            Route::post('/orders/{orderId}/acceptance-letter/send-wa', [\App\Http\Controllers\ServiceOfficer\AcceptanceLetterController::class, 'sendWa']);
        });

        // ── Tukang Jaga ───────────────────────────────────────────────────────────────
        Route::middleware(['role:tukang_jaga'])->prefix('tukang-jaga')->group(function () {
            Route::get('/shifts',                              [\App\Http\Controllers\TukangJaga\ShiftController::class, 'myShifts']);
            Route::get('/shifts/{id}',                         [\App\Http\Controllers\TukangJaga\ShiftController::class, 'show']);
            Route::post('/shifts/{id}/checkin',                [\App\Http\Controllers\TukangJaga\ShiftController::class, 'checkin']);
            Route::post('/shifts/{id}/checkout',               [\App\Http\Controllers\TukangJaga\ShiftController::class, 'checkout']);
            Route::post('/shifts/{id}/switch',                 [\App\Http\Controllers\TukangJaga\ShiftController::class, 'switchShift']);
            Route::get('/orders/{orderId}/deliveries',         [\App\Http\Controllers\TukangJaga\DeliveryController::class, 'index']);
            Route::post('/shifts/{shiftId}/receive',           [\App\Http\Controllers\TukangJaga\DeliveryController::class, 'receive']);
        });

        // ── Tukang Foto — Gallery Links (Google Drive) ────────────────────
        Route::prefix('tukang-foto')->group(function () {
            Route::get('/orders/{orderId}/gallery-links',     [\App\Http\Controllers\TukangFoto\GalleryLinkController::class, 'index']);
            Route::post('/orders/{orderId}/gallery-links',    [\App\Http\Controllers\TukangFoto\GalleryLinkController::class, 'store']);
            Route::delete('/orders/{orderId}/gallery-links/{id}', [\App\Http\Controllers\TukangFoto\GalleryLinkController::class, 'destroy']);
        });

        // ── Consumer: gallery links (only after payment confirmed) ──────
        Route::get('/consumer/orders/{orderId}/gallery-links', [\App\Http\Controllers\TukangFoto\GalleryLinkController::class, 'consumerIndex']);
        // ── SO/internal: gallery links (always visible) ──────────────────
        Route::get('/orders/{orderId}/gallery-links',         [\App\Http\Controllers\TukangFoto\GalleryLinkController::class, 'index']);

        // ── Petugas Akta Kematian ────────────────────────────────────────
        Route::prefix('petugas-akta')->group(function () {
            Route::get('/orders',                              [\App\Http\Controllers\PetugasAkta\AktaController::class, 'index']);
            Route::get('/orders/{orderId}',                    [\App\Http\Controllers\PetugasAkta\AktaController::class, 'show']);
            Route::put('/orders/{orderId}/progress',           [\App\Http\Controllers\PetugasAkta\AktaController::class, 'updateProgress']);
            Route::post('/orders/{orderId}/hand-over',         [\App\Http\Controllers\PetugasAkta\AktaController::class, 'handOver']);
        });

        // ── v1.14 — Vendor/Tukang Foto Attendance ────────────────────────────
        Route::prefix('vendor')->group(function () {
            Route::post('/attendances/{id}/check-in',             [\App\Http\Controllers\Vendor\AttendanceController::class,   'checkIn']);
            Route::post('/attendances/{id}/check-out',            [\App\Http\Controllers\Vendor\AttendanceController::class,   'checkOut']);
        });

        // ── v1.14 — Driver Vehicle Trip Logs ──────────────────────────────────
        Route::middleware('role:' . UserRole::DRIVER->value)->prefix('driver')->group(function () {
            Route::post('/vehicle-trip-logs',                     [\App\Http\Controllers\Driver\VehicleTripLogController::class, 'store']);
            Route::get('/vehicle-trip-logs',                      [\App\Http\Controllers\Driver\VehicleTripLogController::class, 'index']);
            Route::put('/vehicle-trip-logs/{id}',                 [\App\Http\Controllers\Driver\VehicleTripLogController::class, 'update']);
        });

        // ── v1.14 — Dekor Daily Package ───────────────────────────────────────
        Route::middleware('role:' . UserRole::DEKOR->value)->prefix('dekor')->group(function () {
            Route::get('/orders/{orderId}/daily-package',         [\App\Http\Controllers\Dekor\DailyPackageController::class,  'index']);
            Route::post('/orders/{orderId}/daily-package',        [\App\Http\Controllers\Dekor\DailyPackageController::class,  'store']);
        });

        // ── v1.14 — Shared: Consumables & Billing per Order ──────────────────
        Route::prefix('orders/{orderId}')->group(function () {
            Route::get('/consumables',                            [\App\Http\Controllers\ConsumableController::class,          'index']);
            Route::post('/consumables',                           [\App\Http\Controllers\ConsumableController::class,          'store']);
            Route::put('/consumables/{id}',                       [\App\Http\Controllers\ConsumableController::class,          'update']);
            Route::get('/billing',                                [\App\Http\Controllers\BillingController::class,             'index']);
            Route::get('/attendances',                            [\App\Http\Controllers\ServiceOfficer\AttendanceController::class, 'orderAttendances']);
        });

        // ── v1.14 — Purchasing: Billing finalize ──────────────────────────────
        Route::middleware('role:' . implode(',', [UserRole::FINANCE->value, UserRole::PURCHASING->value]))->prefix('purchasing')->group(function () {
            Route::put('/orders/{orderId}/billing-items/{itemId}', [\App\Http\Controllers\BillingController::class,            'update']);
            Route::get('/orders/{orderId}/billing/total',         [\App\Http\Controllers\BillingController::class,             'total']);
            Route::get('/billing/export/{orderId}',               [\App\Http\Controllers\BillingExportController::class,       'exportPdf']);
        });

        // ── Wage Rates — Purchasing set tarif upah per role ────────────────
        Route::middleware('role:' . implode(',', [UserRole::PURCHASING->value, UserRole::FINANCE->value]))->prefix('purchasing/wage-rates')->group(function () {
            Route::get('/',                                          [\App\Http\Controllers\Purchasing\WageRateController::class, 'index']);
            Route::post('/',                                         [\App\Http\Controllers\Purchasing\WageRateController::class, 'store']);
            Route::put('/{id}',                                      [\App\Http\Controllers\Purchasing\WageRateController::class, 'update']);
            Route::delete('/{id}',                                   [\App\Http\Controllers\Purchasing\WageRateController::class, 'destroy']);
        });

        // ── Wage Claims — Purchasing review & bayar klaim upah ───────────
        Route::middleware('role:' . implode(',', [UserRole::PURCHASING->value, UserRole::FINANCE->value]))->prefix('purchasing/wage-claims')->group(function () {
            Route::get('/',                                          [\App\Http\Controllers\Purchasing\WageClaimController::class, 'index']);
            Route::get('/summary',                                   [\App\Http\Controllers\Purchasing\WageClaimController::class, 'summary']);
            Route::get('/{id}',                                      [\App\Http\Controllers\Purchasing\WageClaimController::class, 'show']);
            Route::put('/{id}/approve',                              [\App\Http\Controllers\Purchasing\WageClaimController::class, 'approve']);
            Route::put('/{id}/reject',                               [\App\Http\Controllers\Purchasing\WageClaimController::class, 'reject']);
            Route::post('/{id}/pay',                                 [\App\Http\Controllers\Purchasing\WageClaimController::class, 'pay']);
        });

        // ── Wage Claims — Vendor (tukang foto / angkat peti) ajukan klaim ─
        Route::middleware('role:' . implode(',', [UserRole::TUKANG_FOTO->value, UserRole::TUKANG_ANGKAT_PETI->value]))->prefix('vendor/wage-claims')->group(function () {
            Route::get('/',                                          [\App\Http\Controllers\Vendor\WageClaimController::class, 'index']);
            Route::get('/summary',                                   [\App\Http\Controllers\Vendor\WageClaimController::class, 'mySummary']);
            Route::post('/',                                         [\App\Http\Controllers\Vendor\WageClaimController::class, 'store']);
            Route::get('/{id}',                                      [\App\Http\Controllers\Vendor\WageClaimController::class, 'show']);
            Route::put('/{id}/confirm',                              [\App\Http\Controllers\Vendor\WageClaimController::class, 'confirmReceived']);
        });

        // ── v1.14 — Super Admin Master Data CRUD (v1.27: Owner read-only) ────
        Route::middleware('role:' . implode(',', [UserRole::SUPER_ADMIN->value, UserRole::OWNER->value]))
            ->prefix('admin/master')->group(function () {
            // GET: Super Admin + Owner (read-only)
            Route::get('/{entity}',                               [\App\Http\Controllers\SuperAdmin\MasterDataController::class, 'index']);
            // Write: Super Admin ONLY (owner_readonly middleware blocks Owner)
            Route::middleware('owner_readonly')->group(function () {
                Route::post('/{entity}',                          [\App\Http\Controllers\SuperAdmin\MasterDataController::class, 'store']);
                Route::put('/{entity}/{id}',                      [\App\Http\Controllers\SuperAdmin\MasterDataController::class, 'update']);
                Route::delete('/{entity}/{id}',                   [\App\Http\Controllers\SuperAdmin\MasterDataController::class, 'destroy']);
            });
        });

        // ── v1.14 — Owner: Attendance Summary + KPI ───────────────────────────
        Route::middleware('role:' . UserRole::OWNER->value)->prefix('owner')->group(function () {
            Route::get('/attendances/summary',                    [\App\Http\Controllers\ServiceOfficer\AttendanceController::class, 'orderAttendances']);
            Route::get('/kpi/periods/{periodId}/summaries',       [\App\Http\Controllers\KPI\KpiController::class,             'summaries']);
            Route::get('/kpi/periods/{periodId}/rankings',        [\App\Http\Controllers\KPI\KpiController::class,             'rankings']);
        });

        // ── v1.16 — Self KPI (any authenticated user) ────────────────────────
        Route::get('/my-kpi',                                     [\App\Http\Controllers\KPI\KpiController::class,             'myKpi']);

        // ── v1.14 — AI Endpoints (rate limited: 10 req/min) ────────────────
        Route::middleware('throttle:ai')->group(function () {
            Route::get('/ai/kpi-analysis/{userId}',               [\App\Http\Controllers\AI\KpiAnalysisController::class,      'analyzeUserKpi']);
            Route::get('/ai/order-summary/{orderId}',             [\App\Http\Controllers\AI\KpiAnalysisController::class,      'orderSummary']);
            Route::get('/ai/recommend-vendor',                    [\App\Http\Controllers\AI\RecommendationController::class,   'recommendVendor']);
            Route::get('/ai/optimize-schedule/{orderId}',         [\App\Http\Controllers\AI\RecommendationController::class,   'optimizeSchedule']);
        });

        // ── v1.17 — WhatsApp Deep Link & Templates (rate limited: 10 req/min) ──
        Route::middleware('throttle:wa')->group(function () {
            Route::get('/wa/templates',                           [\App\Http\Controllers\WaController::class,                  'templates']);
            Route::post('/wa/send',                               [\App\Http\Controllers\WaController::class,                  'send']);
            Route::post('/wa/send-order/{orderId}',               [\App\Http\Controllers\WaController::class,                  'sendOrderConfirmation']);
            Route::get('/wa/logs',                                [\App\Http\Controllers\WaController::class,                  'logs']);
        });

        // ── v1.17 — Terms & Conditions (public within auth) ──────────────
        Route::get('/terms/current',                              function () {
            $terms = \App\Models\TermsAndConditions::current();
            return response()->json(['success' => true, 'data' => $terms]);
        });

        // ── v1.17 — Order State Machine (valid transitions) ─────────────
        Route::get('/orders/{orderId}/next-statuses',             function ($orderId) {
            $order = \App\Models\Order::findOrFail($orderId);
            return response()->json([
                'success' => true,
                'data' => [
                    'current_status' => $order->status,
                    'next_statuses' => \App\Services\OrderStateMachine::nextStatuses($order->status),
                    'is_terminal' => \App\Services\OrderStateMachine::isTerminal($order->status),
                ],
            ]);
        });

        // ── v1.17 — GPS tracking (any auth user can view driver location) ──
        Route::get('/driver/gps/latest/{driverId}',              [\App\Http\Controllers\Driver\GpsTrackingController::class, 'latestLocation']);

        // ── v1.35 — User Location Tracking (semua karyawan, dengan consent) ─
        Route::prefix('user/location')->group(function () {
            Route::post('/',          [\App\Http\Controllers\UserLocationController::class, 'updateLocation']);
            Route::post('/consent',   [\App\Http\Controllers\UserLocationController::class, 'storeConsent']);
            Route::get('/consent',    [\App\Http\Controllers\UserLocationController::class, 'checkConsent']);
        });

        // ── v1.36 — Commands (karyawan terima & acknowledge perintah owner) ─
        Route::prefix('commands')->group(function () {
            Route::get('/my',              [\App\Http\Controllers\Owner\CommandController::class, 'myCommands']);
            Route::get('/history',         [\App\Http\Controllers\Owner\CommandController::class, 'myHistory']);
            Route::post('/{id}/acknowledge', [\App\Http\Controllers\Owner\CommandController::class, 'acknowledge']);
        });

        // ── v1.17 — Daily Attendance (all internal users) ────────────────
        Route::prefix('attendance')->group(function () {
            Route::post('/clock-in',                              [\App\Http\Controllers\Attendance\DailyAttendanceController::class, 'clockIn']);
            Route::post('/clock-out',                             [\App\Http\Controllers\Attendance\DailyAttendanceController::class, 'clockOut']);
            Route::get('/me/today',                               [\App\Http\Controllers\Attendance\DailyAttendanceController::class, 'today']);
            Route::get('/me',                                     [\App\Http\Controllers\Attendance\DailyAttendanceController::class, 'myHistory']);
        });

        // ── v1.25 — Stock-aware package selection ────────────────────────
        Route::get('/packages/stock-check',                       [\App\Http\Controllers\PackageStockController::class, 'index']);

        // ── v1.35 — Photo Evidences (universal foto + geofencing) ────────
        Route::post('/photo-evidences',                           [\App\Http\Controllers\PhotoEvidenceController::class, 'store']);
        Route::get('/photo-evidences',                            [\App\Http\Controllers\PhotoEvidenceController::class, 'index']);

        // ── v1.31 — Funeral Homes & Cemeteries (public search for order form) ──
        Route::get('/funeral-homes',          [\App\Http\Controllers\Admin\FuneralHomeController::class, 'index']);
        Route::get('/funeral-homes/{id}',     [\App\Http\Controllers\Admin\FuneralHomeController::class, 'show']);
        Route::get('/cemeteries',             [\App\Http\Controllers\Admin\CemeteryController::class, 'index']);
        Route::get('/cemeteries/{id}',        [\App\Http\Controllers\Admin\CemeteryController::class, 'show']);
    });
});
