<?php

namespace Tests\Unit;

use App\Models\Order;
use App\Models\Package;
use App\Models\PackageItem;
use App\Models\StockItem;
use App\Models\OrderStockDeduction;
use App\Models\StockAlert;
use App\Models\User;
use App\Services\StockManagementService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class StockManagementServiceTest extends TestCase
{
    use RefreshDatabase;

    private StockManagementService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new StockManagementService();
    }

    public function test_returns_early_if_order_has_no_package(): void
    {
        $order = Order::factory()->create(['package_id' => null]);
        $user = User::factory()->create(['role' => 'service_officer']);

        $result = $this->service->processOrderConfirmation($order, $user->id);

        $this->assertTrue($result['success']);
        $this->assertFalse($result['needs_restock']);
        $this->assertEmpty($result['deductions']);
    }

    public function test_deducts_stock_when_sufficient(): void
    {
        $stockItem = StockItem::factory()->create([
            'current_quantity' => 10,
            'minimum_quantity' => 2,
        ]);

        $package = Package::factory()->create();
        $packageItem = PackageItem::factory()->create([
            'package_id' => $package->id,
            'stock_item_id' => $stockItem->id,
            'deduct_quantity' => 3,
        ]);

        $order = Order::factory()->create(['package_id' => $package->id]);
        $user = User::factory()->create(['role' => 'service_officer']);

        $result = $this->service->processOrderConfirmation($order, $user->id);

        $this->assertTrue($result['success']);
        $this->assertFalse($result['needs_restock']);
        $this->assertCount(1, $result['deductions']);

        $stockItem->refresh();
        $this->assertEquals(7, $stockItem->current_quantity);

        $deduction = OrderStockDeduction::where('order_id', $order->id)->first();
        $this->assertNotNull($deduction);
        $this->assertTrue($deduction->is_sufficient);
        $this->assertEquals(10, $deduction->stock_before);
        $this->assertEquals(7, $deduction->stock_after);
    }

    public function test_flags_insufficient_stock_without_blocking(): void
    {
        $stockItem = StockItem::factory()->create([
            'current_quantity' => 1,
            'minimum_quantity' => 2,
        ]);

        $package = Package::factory()->create();
        PackageItem::factory()->create([
            'package_id' => $package->id,
            'stock_item_id' => $stockItem->id,
            'deduct_quantity' => 5,
        ]);

        $order = Order::factory()->create(['package_id' => $package->id]);
        $user = User::factory()->create(['role' => 'service_officer']);

        $result = $this->service->processOrderConfirmation($order, $user->id);

        $this->assertTrue($result['success']);
        $this->assertTrue($result['needs_restock']);
        $this->assertNotEmpty($result['insufficient_items']);

        // Stock should NOT be deducted when insufficient
        $stockItem->refresh();
        $this->assertEquals(1, $stockItem->current_quantity);

        $order->refresh();
        $this->assertTrue($order->needs_restock);
    }

    public function test_creates_stock_alert_when_below_minimum(): void
    {
        $stockItem = StockItem::factory()->create([
            'current_quantity' => 3,
            'minimum_quantity' => 5,
        ]);

        $package = Package::factory()->create();
        PackageItem::factory()->create([
            'package_id' => $package->id,
            'stock_item_id' => $stockItem->id,
            'deduct_quantity' => 1,
        ]);

        $order = Order::factory()->create(['package_id' => $package->id]);
        $user = User::factory()->create(['role' => 'service_officer']);

        $this->service->processOrderConfirmation($order, $user->id);

        $alert = StockAlert::where('stock_item_id', $stockItem->id)->first();
        $this->assertNotNull($alert);
        $this->assertEquals('low_stock', $alert->alert_type);
    }
}
