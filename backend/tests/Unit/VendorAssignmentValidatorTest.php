<?php

namespace Tests\Unit;

use App\Models\VendorRoleMaster;
use App\Services\VendorAssignmentValidator;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * v1.40 — Validator enforce fee=0 untuk vendor yang tidak dibayar SM
 * (contoh: pemuka_agama — keluarga bayar langsung).
 */
class VendorAssignmentValidatorTest extends TestCase
{
    use RefreshDatabase;

    private VendorAssignmentValidator $validator;

    protected function setUp(): void
    {
        parent::setUp();
        $this->validator = new VendorAssignmentValidator();
    }

    public function test_pemuka_agama_fee_forced_to_zero(): void
    {
        $role = VendorRoleMaster::create([
            'role_code' => 'pemuka_agama',
            'role_name' => 'Pemuka Agama',
            'category' => 'religious',
            'is_paid_by_sm' => false,
        ]);

        $result = $this->validator->normalize([
            'vendor_role_id' => $role->id,
            'source' => 'internal',
            'user_id' => 'some-uuid',
            'fee' => 500000, // coba set fee → harus di-override jadi 0
        ]);

        $this->assertEquals(0, $result['fee']);
        $this->assertEquals('external_consumer', $result['source']);
        $this->assertNull($result['user_id']);
    }

    public function test_pemuka_agama_external_so_source_preserved(): void
    {
        // Kalau SO yang kasih vendor external, source tetap 'external_so' (tidak di-override ke consumer)
        $role = VendorRoleMaster::create([
            'role_code' => 'pemuka_agama',
            'role_name' => 'Pemuka Agama',
            'category' => 'religious',
            'is_paid_by_sm' => false,
        ]);

        $result = $this->validator->normalize([
            'vendor_role_id' => $role->id,
            'source' => 'external_so',
            'fee' => 500000,
        ]);

        $this->assertEquals(0, $result['fee']);
        $this->assertEquals('external_so', $result['source']);
    }

    public function test_regular_paid_vendor_fee_preserved(): void
    {
        $role = VendorRoleMaster::create([
            'role_code' => 'fotografer',
            'role_name' => 'Fotografer',
            'category' => 'documentation',
            'is_paid_by_sm' => true,
        ]);

        $result = $this->validator->normalize([
            'vendor_role_id' => $role->id,
            'source' => 'internal',
            'fee' => 500000,
        ]);

        $this->assertEquals(500000, $result['fee']);
        $this->assertEquals('internal', $result['source']);
    }

    public function test_musisi_not_paid_by_sm_fee_zero(): void
    {
        // Musisi juga kadang keluarga bayar langsung (misalnya pakai grup gereja)
        $role = VendorRoleMaster::create([
            'role_code' => 'musisi_gereja',
            'role_name' => 'Musisi Gereja',
            'category' => 'music',
            'is_paid_by_sm' => false,
        ]);

        $result = $this->validator->normalize([
            'vendor_role_id' => $role->id,
            'source' => 'external',
            'fee' => 200000,
        ]);

        $this->assertEquals(0, $result['fee']);
        // Non-pemuka agama tidak di-force external
        $this->assertEquals('external', $result['source']);
    }

    public function test_throws_when_role_not_found(): void
    {
        $this->expectException(\InvalidArgumentException::class);

        $this->validator->normalize([
            'vendor_role_id' => '00000000-0000-0000-0000-000000000000',
            'fee' => 100000,
        ]);
    }

    public function test_is_paid_by_sm_true_by_default(): void
    {
        $role = VendorRoleMaster::create([
            'role_code' => 'test_role',
            'role_name' => 'Test',
            'category' => 'other',
            // is_paid_by_sm tidak diset, default true
        ]);

        $this->assertTrue($this->validator->isPaidBySm($role->id));
    }

    public function test_rule_summary_for_pemuka_agama(): void
    {
        $role = VendorRoleMaster::create([
            'role_code' => 'pemuka_agama',
            'role_name' => 'Pemuka Agama',
            'category' => 'religious',
            'is_paid_by_sm' => false,
        ]);

        $rule = $this->validator->getRuleForRole($role->id);

        $this->assertNotNull($rule);
        $this->assertEquals(0, $rule['enforced_fee']);
        $this->assertEquals('external_consumer', $rule['enforced_source']);
    }

    public function test_rule_summary_null_for_paid_regular_role(): void
    {
        $role = VendorRoleMaster::create([
            'role_code' => 'dekor',
            'role_name' => 'Dekor',
            'category' => 'decoration',
            'is_paid_by_sm' => true,
        ]);

        $this->assertNull($this->validator->getRuleForRole($role->id));
    }

    public function test_normalize_passthrough_when_no_vendor_role_id(): void
    {
        $input = ['fee' => 100000, 'notes' => 'test'];
        $result = $this->validator->normalize($input);

        $this->assertEquals($input, $result);
    }
}
