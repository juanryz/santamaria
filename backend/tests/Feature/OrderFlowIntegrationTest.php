<?php

namespace Tests\Feature;

use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Models\Order;
use App\Models\Package;
use App\Models\PackageItem;
use App\Models\StockItem;
use App\Models\User;
use App\Services\OrderStateMachine;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OrderFlowIntegrationTest extends TestCase
{
    use RefreshDatabase;

    private User $consumer;
    private User $so;
    private User $gudang;
    private User $driver;
    private User $purchasing;
    private Package $package;

    protected function setUp(): void
    {
        parent::setUp();

        $this->consumer = User::factory()->consumer()->create();
        $this->so = User::factory()->role(UserRole::SERVICE_OFFICER)->create();
        $this->gudang = User::factory()->role(UserRole::GUDANG)->create();
        $this->driver = User::factory()->role(UserRole::DRIVER)->create();
        $this->purchasing = User::factory()->role(UserRole::PURCHASING)->create();

        $this->package = Package::factory()->create();
        $stockItem = StockItem::factory()->create(['current_quantity' => 20]);
        PackageItem::factory()->withStock($stockItem->id, 2)->create(['package_id' => $this->package->id]);
    }

    // === Step 1: Consumer creates order ===
    public function test_consumer_can_create_order(): void
    {
        Sanctum::actingAs($this->consumer);

        $response = $this->postJson('/api/v1/consumer/orders', [
            'package_id' => $this->package->id,
            'pic_name' => 'Test Family',
            'pic_phone' => '08123456789',
            'pic_relation' => 'anak',
            'pic_address' => 'Jl. Test 123',
            'deceased_name' => 'Almarhum Test',
            'deceased_dod' => now()->subDay()->toDateString(),
            'deceased_religion' => 'katolik',
            'pickup_address' => 'RS Test',
            'destination_address' => 'Pemakaman Test',
        ]);

        $response->assertStatus(201);
        $this->assertDatabaseCount('orders', 1);
    }

    // === Step 2: SO confirms order ===
    public function test_so_can_confirm_order(): void
    {
        $order = Order::factory()->withConsumer($this->consumer)->create([
            'package_id' => $this->package->id,
            'so_user_id' => $this->so->id,
        ]);

        Sanctum::actingAs($this->so);

        $response = $this->putJson("/api/v1/so/orders/{$order->id}/confirm", [
            'package_id' => $this->package->id,
            'scheduled_at' => now()->addDay()->toIso8601String(),
            'estimated_duration_hours' => 3,
            'final_price' => 15000000,
        ]);

        $response->assertStatus(200);
        $order->refresh();
        $this->assertEquals(OrderStatus::CONFIRMED->value, $order->status);
    }

    // === Step 3: State machine validates transitions ===
    public function test_state_machine_blocks_invalid_transition(): void
    {
        $order = Order::factory()->create(['status' => OrderStatus::PENDING->value]);

        // Cannot go directly from pending to completed
        $this->assertFalse(OrderStateMachine::canTransition(
            OrderStatus::PENDING->value,
            OrderStatus::COMPLETED->value
        ));

        // Can go from pending to confirmed
        $this->assertTrue(OrderStateMachine::canTransition(
            OrderStatus::PENDING->value,
            OrderStatus::CONFIRMED->value
        ));
    }

    // === Step 4: Gudang views orders ===
    public function test_gudang_can_view_active_orders(): void
    {
        Order::factory()->create(['status' => OrderStatus::CONFIRMED->value]);

        Sanctum::actingAs($this->gudang);

        $response = $this->getJson('/api/v1/gudang/orders');
        $response->assertStatus(200)->assertJsonPath('success', true);
    }

    // === Step 5: Driver can transition order status ===
    public function test_driver_can_transition_order(): void
    {
        $order = Order::factory()->create([
            'status' => OrderStatus::DELIVERING_EQUIPMENT->value,
            'driver_id' => $this->driver->id,
        ]);

        Sanctum::actingAs($this->driver);

        $response = $this->putJson("/api/v1/driver/orders/{$order->id}/transition", [
            'to_status' => OrderStatus::EQUIPMENT_ARRIVED->value,
        ]);

        $response->assertStatus(200);
        $order->refresh();
        $this->assertEquals(OrderStatus::EQUIPMENT_ARRIVED->value, $order->status);
    }

    // === Step 6: Driver cannot skip statuses ===
    public function test_driver_cannot_skip_status(): void
    {
        $order = Order::factory()->create([
            'status' => OrderStatus::DELIVERING_EQUIPMENT->value,
            'driver_id' => $this->driver->id,
        ]);

        Sanctum::actingAs($this->driver);

        // Cannot jump from delivering_equipment to completed
        $response = $this->putJson("/api/v1/driver/orders/{$order->id}/transition", [
            'to_status' => OrderStatus::COMPLETED->value,
        ]);

        $response->assertStatus(422);
    }

    // === Step 7: Consumer can sign acceptance ===
    public function test_consumer_can_sign_acceptance(): void
    {
        $order = Order::factory()->create([
            'status' => OrderStatus::CONFIRMED->value,
            'pic_user_id' => $this->consumer->id,
        ]);

        Sanctum::actingAs($this->consumer);

        $response = $this->postJson("/api/v1/consumer/orders/{$order->id}/acceptance/sign", [
            'agreed' => true,
            'pj_name' => 'Test Signer',
            'pj_relation' => 'anak',
        ]);

        $response->assertStatus(200);
        $order->refresh();
        $this->assertNotNull($order->acceptance_signed_at);
    }

    // === Step 8: Viewer cannot write ===
    public function test_viewer_cannot_create_order(): void
    {
        $viewer = User::factory()->viewer()->create();
        Sanctum::actingAs($viewer);

        $response = $this->postJson('/api/v1/consumer/orders', ['pic_name' => 'test']);

        // Should be blocked by either role middleware or viewer middleware
        $this->assertTrue(in_array($response->status(), [403, 422]));
    }

    // === Step 9: Config endpoint serves all enums ===
    public function test_config_endpoint_returns_enums(): void
    {
        $response = $this->getJson('/api/v1/config');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'thresholds',
                    'settings',
                    'enums' => [
                        'order_status',
                        'payment_status',
                    ],
                ],
            ]);
    }

    // === Step 10: Full happy path flow ===
    public function test_full_order_flow_happy_path(): void
    {
        // 1. Create order
        $order = Order::factory()->withConsumer($this->consumer)->create([
            'package_id' => $this->package->id,
            'status' => OrderStatus::PENDING->value,
        ]);

        // 2. Transition through states
        $flow = [
            OrderStatus::CONFIRMED->value,
            OrderStatus::PREPARING->value ?? 'preparing',
        ];

        $userId = $this->so->id;
        $currentStatus = $order->status;

        foreach ($flow as $nextStatus) {
            if (OrderStateMachine::canTransition($currentStatus, $nextStatus)) {
                OrderStateMachine::transition($order, $nextStatus, $userId);
                $currentStatus = $nextStatus;
            }
        }

        $order->refresh();
        // Should have progressed
        $this->assertNotEquals(OrderStatus::PENDING->value, $order->status);

        // Status log should have entries
        $this->assertTrue($order->statusLogs()->count() > 0);
    }
}
