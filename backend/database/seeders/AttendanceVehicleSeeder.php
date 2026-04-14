<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AttendanceVehicleSeeder extends Seeder
{
    public function run(): void
    {
        $this->seedAttendanceLocations();
        $this->seedWorkShifts();
        $this->seedVehicleInspectionMaster();
    }

    private function seedAttendanceLocations(): void
    {
        $locations = [
            ['Kantor Santa Maria', 'Jl. Pandanaran No. 123, Semarang', -6.9666, 110.4196, 100],
            ['Gudang Santa Maria', 'Jl. Industri No. 45, Semarang', -6.9720, 110.4250, 150],
        ];

        foreach ($locations as [$name, $address, $lat, $lng, $radius]) {
            DB::table('attendance_locations')->insertOrIgnore([
                'id' => Str::uuid(), 'name' => $name, 'address' => $address,
                'latitude' => $lat, 'longitude' => $lng, 'radius_meters' => $radius,
                'is_active' => true, 'created_at' => now(), 'updated_at' => now(),
            ]);
        }
    }

    private function seedWorkShifts(): void
    {
        $shifts = [
            ['Pagi', '07:00', '15:00', 15, 15],
            ['Siang', '12:00', '20:00', 15, 15],
            ['Malam', '19:00', '03:00', 15, 15],
            ['Full Day', '08:00', '17:00', 30, 30],
        ];

        foreach ($shifts as [$name, $start, $end, $late, $early]) {
            DB::table('work_shifts')->insertOrIgnore([
                'id' => Str::uuid(), 'shift_name' => $name,
                'start_time' => $start, 'end_time' => $end,
                'late_tolerance_minutes' => $late, 'early_leave_tolerance_minutes' => $early,
                'is_active' => true, 'created_at' => now(), 'updated_at' => now(),
            ]);
        }
    }

    private function seedVehicleInspectionMaster(): void
    {
        $items = [
            // Exterior
            ['exterior', 'Body kendaraan (penyok/gores)', 'boolean', true],
            ['exterior', 'Lampu depan', 'boolean', true],
            ['exterior', 'Lampu belakang & rem', 'boolean', true],
            ['exterior', 'Lampu sein kanan & kiri', 'boolean', true],
            ['exterior', 'Wiper & washer', 'boolean', false],
            ['exterior', 'Kaca spion kanan & kiri', 'boolean', false],
            ['exterior', 'Ban depan (kondisi & tekanan)', 'boolean', true],
            ['exterior', 'Ban belakang (kondisi & tekanan)', 'boolean', true],
            ['exterior', 'Ban serep', 'boolean', false],
            // Interior
            ['interior', 'Kebersihan kabin', 'boolean', false],
            ['interior', 'AC berfungsi', 'boolean', false],
            ['interior', 'Sabuk pengaman', 'boolean', true],
            ['interior', 'Dashboard & indikator', 'boolean', true],
            ['interior', 'Klakson', 'boolean', true],
            ['interior', 'Kunci & handle pintu', 'boolean', false],
            // Engine
            ['engine', 'Oli mesin', 'boolean', true],
            ['engine', 'Air radiator', 'boolean', true],
            ['engine', 'Minyak rem', 'boolean', true],
            ['engine', 'Aki / battery', 'boolean', true],
            ['engine', 'Filter udara', 'boolean', false],
            ['engine', 'V-belt / fan belt', 'boolean', false],
            // Safety
            ['safety', 'P3K / First Aid Kit', 'boolean', false],
            ['safety', 'Segitiga pengaman', 'boolean', true],
            ['safety', 'APAR (alat pemadam)', 'boolean', true],
            ['safety', 'Dongkrak & kunci roda', 'boolean', false],
            // Documents
            ['documents', 'STNK berlaku', 'boolean', true],
            ['documents', 'SIM driver berlaku', 'boolean', true],
            ['documents', 'Asuransi kendaraan', 'boolean', false],
            ['documents', 'Kartu uji KIR (jika wajib)', 'boolean', false],
        ];

        foreach ($items as $i => [$cat, $name, $type, $critical]) {
            DB::table('vehicle_inspection_master')->insertOrIgnore([
                'id' => Str::uuid(), 'category' => $cat, 'item_name' => $name,
                'check_type' => $type, 'sort_order' => $i + 1,
                'is_critical' => $critical, 'is_active' => true,
                'created_at' => now(), 'updated_at' => now(),
            ]);
        }
    }
}
