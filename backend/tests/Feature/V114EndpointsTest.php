<?php

namespace Tests\Feature;

use App\Enums\UserRole;
use App\Models\User;
use App\Models\CoffinOrder;
use App\Models\Order;
use App\Models\StockItem;
use App\Models\EquipmentMaster;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class V114EndpointsTest extends TestCase
{
    use RefreshDatabase;

    private function actAsGudang(): User
    {
        $user = User::factory()->create(['role' => UserRole::GUDANG->value]);
        Sanctum::actingAs($user);
        return $user;
    }

    private function actAsSO(): User
    {
        $user = User::factory()->create(['role' => UserRole::SERVICE_OFFICER->value]);
        Sanctum::actingAs($user);
        return $user;
    }

    private function actAsHRD(): User
    {
        $user = User::factory()->create(['role' => UserRole::HRD->value]);
        Sanctum::actingAs($user);
        return $user;
    }

    // === Coffin Orders ===

    public function test_gudang_can_create_coffin_order(): void
    {
        $this->actAsGudang();

        $response = $this->postJson('/api/v1/gudang/coffin-orders', [
            'kode_peti' => 'PTI-TEST-001',
            'finishing_type' => 'melamin',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['id', 'coffin_order_number', 'stages']]);
    }

    public function test_gudang_can_list_coffin_orders(): void
    {
        $this->actAsGudang();

        $response = $this->getJson('/api/v1/gudang/coffin-orders');

        $response->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    // === Equipment ===

    public function test_gudang_can_list_equipment_master(): void
    {
        $this->actAsGudang();

        $response = $this->getJson('/api/v1/gudang/equipment-master');

        $response->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    public function test_gudang_can_view_stock_alerts(): void
    {
        $this->actAsGudang();

        $response = $this->getJson('/api/v1/gudang/stock-alerts');

        $response->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    // === Stock Form ===

    public function test_gudang_can_submit_stock_form(): void
    {
        $this->actAsGudang();

        $stockItem = StockItem::factory()->create(['current_quantity' => 10]);

        $response = $this->postJson('/api/v1/gudang/stock/form', [
            'stock_item_id' => $stockItem->id,
            'form_type' => 'pengambilan',
            'quantity' => 3,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $stockItem->refresh();
        $this->assertEquals(7, $stockItem->current_quantity);
    }

    public function test_stock_form_rejects_insufficient(): void
    {
        $this->actAsGudang();

        $stockItem = StockItem::factory()->create(['current_quantity' => 2]);

        $response = $this->postJson('/api/v1/gudang/stock/form', [
            'stock_item_id' => $stockItem->id,
            'form_type' => 'pengambilan',
            'quantity' => 10,
        ]);

        $response->assertStatus(422);
    }

    // === SO Stock Check Preview ===

    public function test_so_can_preview_stock_check(): void
    {
        $this->actAsSO();

        $order = Order::factory()->create();
        $package = \App\Models\Package::factory()->create();

        $response = $this->getJson("/api/v1/so/orders/{$order->id}/stock-check?package_id={$package->id}");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['items', 'all_sufficient']]);
    }

    // === HRD ===

    public function test_hrd_can_view_attendances(): void
    {
        $this->actAsHRD();

        $response = $this->getJson('/api/v1/hrd/attendances');

        $response->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    public function test_hrd_can_view_kpi_metrics(): void
    {
        $this->actAsHRD();

        $response = $this->getJson('/api/v1/hrd/kpi/metrics');

        $response->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    // === KPI Self ===

    public function test_any_user_can_view_own_kpi(): void
    {
        $user = User::factory()->create(['role' => UserRole::DRIVER->value]);
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/my-kpi');

        $response->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    // === Unauthorized Access ===

    public function test_consumer_cannot_access_gudang_endpoints(): void
    {
        $user = User::factory()->create(['role' => UserRole::CONSUMER->value]);
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/gudang/coffin-orders');

        $response->assertStatus(403);
    }

    public function test_viewer_cannot_access_write_endpoints(): void
    {
        $user = User::factory()->create(['role' => UserRole::VIEWER->value]);
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/gudang/coffin-orders', [
            'kode_peti' => 'TEST',
            'finishing_type' => 'melamin',
        ]);

        $response->assertStatus(403);
    }
}
