<?php

namespace Tests\Unit;

use App\Models\Order;
use App\Models\Package;
use App\Models\TukangJagaShift;
use App\Models\TukangJagaWageConfig;
use App\Services\TukangJagaShiftGenerator;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * v1.40 — Auto-generate tukang jaga shifts saat order confirmed.
 * Aturan: 2 shift/hari (pagi + malam) × service_duration_days.
 */
class TukangJagaShiftGeneratorTest extends TestCase
{
    use RefreshDatabase;

    private TukangJagaShiftGenerator $generator;

    protected function setUp(): void
    {
        parent::setUp();
        $this->generator = new TukangJagaShiftGenerator();
    }

    public function test_generates_shifts_from_order_service_duration(): void
    {
        $order = Order::factory()->create([
            'scheduled_at' => now()->addDay()->setTime(10, 0),
            'service_duration_days' => 5,
        ]);

        $count = $this->generator->generate($order);

        // 5 hari × 2 shift = 10 shift
        $this->assertEquals(10, $count);
        $this->assertEquals(10, TukangJagaShift::where('order_id', $order->id)->count());
    }

    public function test_generates_shifts_from_package_duration_when_order_empty(): void
    {
        $package = Package::factory()->create(['service_duration_days' => 7]);

        $order = Order::factory()->create([
            'scheduled_at' => now()->addDay(),
            'package_id' => $package->id,
            'service_duration_days' => null,
        ]);

        $count = $this->generator->generate($order);

        $this->assertEquals(14, $count); // 7 × 2
    }

    public function test_defaults_to_3_days_when_no_duration_set(): void
    {
        $order = Order::factory()->create([
            'scheduled_at' => now()->addDay(),
            'service_duration_days' => null,
            'package_id' => null,
        ]);

        $count = $this->generator->generate($order);

        $this->assertEquals(6, $count); // 3 × 2 (default)
    }

    public function test_returns_zero_when_order_has_no_scheduled_at(): void
    {
        $order = Order::factory()->create([
            'scheduled_at' => null,
            'service_duration_days' => 5,
        ]);

        $count = $this->generator->generate($order);

        $this->assertEquals(0, $count);
        $this->assertEquals(0, TukangJagaShift::where('order_id', $order->id)->count());
    }

    public function test_is_idempotent_no_duplicate_shifts(): void
    {
        $order = Order::factory()->create([
            'scheduled_at' => now()->addDay(),
            'service_duration_days' => 3,
        ]);

        // First run
        $firstCount = $this->generator->generate($order);
        $this->assertEquals(6, $firstCount);

        // Second run — should NOT create more
        $secondCount = $this->generator->generate($order);
        $this->assertEquals(0, $secondCount);

        $this->assertEquals(6, TukangJagaShift::where('order_id', $order->id)->count());
    }

    public function test_pagi_and_malam_shifts_alternate(): void
    {
        $order = Order::factory()->create([
            'scheduled_at' => now()->addDay()->setTime(0, 0),
            'service_duration_days' => 2,
        ]);

        $this->generator->generate($order);

        $shifts = TukangJagaShift::where('order_id', $order->id)
            ->orderBy('shift_number')
            ->get();

        $this->assertEquals('pagi', $shifts[0]->shift_type);
        $this->assertEquals('malam', $shifts[1]->shift_type);
        $this->assertEquals('pagi', $shifts[2]->shift_type);
        $this->assertEquals('malam', $shifts[3]->shift_type);
    }

    public function test_meals_included_defaults_false_per_v140(): void
    {
        $order = Order::factory()->create([
            'scheduled_at' => now()->addDay(),
            'service_duration_days' => 1,
        ]);

        $this->generator->generate($order);

        $shifts = TukangJagaShift::where('order_id', $order->id)->get();
        foreach ($shifts as $shift) {
            $this->assertFalse($shift->meals_included);
        }
    }

    public function test_shift_pagi_times_06_to_18(): void
    {
        $scheduledAt = now()->addDay()->startOfDay();
        $order = Order::factory()->create([
            'scheduled_at' => $scheduledAt,
            'service_duration_days' => 1,
        ]);

        $this->generator->generate($order);

        $pagi = TukangJagaShift::where('order_id', $order->id)
            ->where('shift_type', 'pagi')
            ->first();

        $this->assertEquals(6, $pagi->scheduled_start->hour);
        $this->assertEquals(18, $pagi->scheduled_end->hour);
    }

    public function test_shift_malam_crosses_midnight(): void
    {
        $scheduledAt = now()->addDay()->startOfDay();
        $order = Order::factory()->create([
            'scheduled_at' => $scheduledAt,
            'service_duration_days' => 1,
        ]);

        $this->generator->generate($order);

        $malam = TukangJagaShift::where('order_id', $order->id)
            ->where('shift_type', 'malam')
            ->first();

        $this->assertEquals(18, $malam->scheduled_start->hour);
        $this->assertEquals(6, $malam->scheduled_end->hour);
        // End hari berikutnya
        $this->assertTrue($malam->scheduled_end->gt($malam->scheduled_start));
    }

    public function test_uses_wage_config_when_available(): void
    {
        TukangJagaWageConfig::create([
            'label' => 'Shift Pagi Default',
            'shift_type' => 'pagi',
            'rate' => 150000,
            'currency' => 'IDR',
            'is_active' => true,
        ]);

        $order = Order::factory()->create([
            'scheduled_at' => now()->addDay(),
            'service_duration_days' => 1,
        ]);

        $this->generator->generate($order);

        $pagi = TukangJagaShift::where('order_id', $order->id)
            ->where('shift_type', 'pagi')
            ->first();

        $this->assertNotNull($pagi->wage_config_id);
    }
}
