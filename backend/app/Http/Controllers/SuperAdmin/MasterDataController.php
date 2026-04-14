<?php

namespace App\Http\Controllers\SuperAdmin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MasterDataController extends Controller
{
    private array $entityMap = [
        'consumables' => ['table' => 'consumable_master', 'model' => \App\Models\ConsumableMaster::class],
        'billing-items' => ['table' => 'billing_item_master', 'model' => \App\Models\BillingItemMaster::class],
        'coffin-stages' => ['table' => 'coffin_stage_master', 'model' => \App\Models\CoffinStageMaster::class],
        'coffin-qc-criteria' => ['table' => 'coffin_qc_criteria_master', 'model' => \App\Models\CoffinQcCriteriaMaster::class],
        'death-cert-docs' => ['table' => 'death_cert_doc_master', 'model' => \App\Models\DeathCertDocMaster::class],
        'dekor-items' => ['table' => 'dekor_item_master', 'model' => \App\Models\DekorItemMaster::class],
        'equipment' => ['table' => 'equipment_master', 'model' => \App\Models\EquipmentMaster::class],
        'vendor-roles' => ['table' => 'vendor_role_master', 'model' => \App\Models\VendorRoleMaster::class],
        'trip-legs' => ['table' => 'trip_leg_master', 'model' => \App\Models\TripLegMaster::class],
        'wa-templates' => ['table' => 'wa_message_templates', 'model' => \App\Models\WaMessageTemplate::class],
        'status-labels' => ['table' => 'order_status_labels', 'model' => \App\Models\OrderStatusLabel::class],
        'terms' => ['table' => 'terms_and_conditions', 'model' => \App\Models\TermsAndConditions::class],
        'attendance-locations' => ['table' => 'attendance_locations', 'model' => \App\Models\AttendanceLocation::class],
        'work-shifts' => ['table' => 'work_shifts', 'model' => \App\Models\WorkShift::class],
        'vehicle-inspection' => ['table' => 'vehicle_inspection_master', 'model' => \App\Models\VehicleInspectionMaster::class],
    ];

    public function index(Request $request, string $entity)
    {
        $config = $this->resolveEntity($entity);
        $items = $config['model']::orderBy('sort_order')->orderBy('created_at')->get();
        return response()->json(['success' => true, 'data' => $items]);
    }

    public function store(Request $request, string $entity)
    {
        $this->authorizeWrite($request);
        $config = $this->resolveEntity($entity);
        $item = $config['model']::create($request->all());
        return response()->json(['success' => true, 'data' => $item], 201);
    }

    public function update(Request $request, string $entity, string $id)
    {
        $this->authorizeWrite($request);
        $config = $this->resolveEntity($entity);
        $item = $config['model']::findOrFail($id);
        $item->update($request->all());
        return response()->json(['success' => true, 'data' => $item]);
    }

    public function destroy(Request $request, string $entity, string $id)
    {
        $this->authorizeWrite($request);
        $config = $this->resolveEntity($entity);
        $item = $config['model']::findOrFail($id);
        $item->update(['is_active' => false]);
        return response()->json(['success' => true, 'message' => 'Deactivated']);
    }

    private function resolveEntity(string $entity): array
    {
        if (!isset($this->entityMap[$entity])) {
            abort(404, "Entity '{$entity}' not found");
        }
        return $this->entityMap[$entity];
    }

    private function authorizeWrite(Request $request): void
    {
        if ($request->user()->role !== 'SUPER_ADMIN') {
            abort(403, 'Only Super Admin can modify master data');
        }
    }
}
