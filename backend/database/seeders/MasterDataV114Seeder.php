<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class MasterDataV114Seeder extends Seeder
{
    public function run(): void
    {
        $this->seedEquipmentMaster();
        $this->seedConsumableMaster();
        $this->seedBillingItemMaster();
        $this->seedDekorItemMaster();
        $this->seedDeathCertDocMaster();
        $this->seedCoffinStageMaster();
        $this->seedCoffinQcCriteriaMaster();
    }

    private function seedEquipmentMaster(): void
    {
        $items = [
            ['KOPER_MISA', 'Piala_Sibori_Patena', 'Piala, Sibori, Patena'],
            ['KOPER_MISA', 'Ampul_Mangkok', 'Ampul & Mangkok'],
            ['KOPER_MISA', 'Purifikatorium', 'Purifikatorium'],
            ['KOPER_MISA', 'Korporale', 'Korporale'],
            ['KOPER_MISA', 'Hosti', 'Hosti'],
            ['KOPER_ROMO', null, 'Koper Romo (Set Liturgi)'],
            ['BOX', null, 'Box Peralatan Umum'],
            ['SOUND', null, 'Sound System Set'],
            ['MEJA', null, 'Meja Altar Portabel'],
            ['TAPLAK', null, 'Taplak Meja'],
            ['PEMBERKATAN', null, 'Set Pemberkatan'],
            ['LAIN', null, 'Lilin Altar'],
            ['LAIN', null, 'Salib Berdiri'],
        ];

        foreach ($items as $i => [$cat, $sub, $name]) {
            DB::table('equipment_master')->insertOrIgnore([
                'id' => Str::uuid(),
                'category' => $cat,
                'sub_category' => $sub,
                'item_name' => $name,
                'item_code' => 'EQ-' . str_pad($i + 1, 3, '0', STR_PAD_LEFT),
                'default_qty' => 1,
                'unit' => 'pcs',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    private function seedConsumableMaster(): void
    {
        $items = [
            ['CLN', 'Eau de Cologne', 'btl', 'kosmetik'],
            ['LLN', 'Lilin', 'btl', 'liturgi'],
            ['AQU', 'Air Minum', 'dos', 'konsumsi'],
            ['PMN', 'Permen', 'pak', 'konsumsi'],
            ['KCG', 'Kacang', 'pak', 'konsumsi'],
            ['KWC', 'Kwaci', 'pak', 'konsumsi'],
            ['SLB', 'Salib Katholik', 'pcs', 'liturgi'],
            ['SPH', 'Sepatu Hitam', 'pcs', 'pakaian'],
            ['SPP', 'Sepatu Putih', 'pcs', 'pakaian'],
            ['LLP', 'Lilin Putih (liturgi)', 'pcs', 'liturgi'],
            ['LLM', 'Lilin Merah (liturgi)', 'pcs', 'liturgi'],
            ['KRU', 'Kartu Ucapan', 'pcs', 'perlengkapan'],
            ['SMK', 'Semangka', 'pcs', 'konsumsi'],
            ['ROT', 'Roti', 'pcs', 'konsumsi'],
            ['HJS', 'Happy Jus', 'pcs', 'konsumsi'],
            ['TSR', 'Teh Sosro', 'pcs', 'konsumsi'],
        ];

        foreach ($items as $i => [$code, $name, $unit, $cat]) {
            DB::table('consumable_master')->insertOrIgnore([
                'id' => Str::uuid(),
                'item_code' => $code,
                'item_name' => $name,
                'unit' => $unit,
                'category' => $cat,
                'sort_order' => $i + 1,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    private function seedBillingItemMaster(): void
    {
        $items = [
            ['EMB', 'Embalming', 'layanan'],
            ['NSN', 'Nisan', 'layanan'],
            ['BNG_SLB', 'Bunga Salib', 'dekorasi'],
            ['BNG_PTI', 'Bunga Atas Peti', 'dekorasi'],
            ['MND', 'Memandikan Jenazah', 'layanan'],
            ['AQU', 'AQUA/PRIMA/CLEO', 'konsumsi'],
            ['ROT', 'Roti', 'konsumsi'],
            ['KWC', 'Kwaci', 'konsumsi'],
            ['KCG', 'Kacang', 'konsumsi'],
            ['PMN', 'Permen', 'konsumsi'],
            ['KRT', 'Kartu Ucapan', 'perlengkapan'],
            ['LLN', 'Lilin', 'liturgi'],
            ['TKG_JG', 'Tukang Jaga', 'layanan'],
            ['RPR', 'Repro', 'layanan'],
            ['FTO', 'Foto Dokumentasi', 'layanan'],
            ['BSL', 'Bus Lelayu', 'transportasi'],
            ['SWA_TRK', 'Sewa Truck/Pick Up', 'transportasi'],
            ['PLR', 'Pelarung', 'layanan'],
            ['TNH', 'Tanah Makam', 'layanan'],
            ['BW', 'Black & White', 'layanan'],
            ['SNT', 'Saint Voice', 'layanan'],
            ['VDO', 'Video Shooting', 'layanan'],
            ['MTR', 'Mutiara', 'layanan'],
            ['IKL', 'Iklan Dukacita', 'layanan'],
            ['MBL', 'Sewa Mobil Jenazah', 'transportasi'],
        ];

        foreach ($items as $i => [$code, $name, $cat]) {
            DB::table('billing_item_master')->insertOrIgnore([
                'id' => Str::uuid(),
                'item_code' => $code,
                'item_name' => $name,
                'category' => $cat,
                'default_unit' => 'unit',
                'default_unit_price' => 0,
                'sort_order' => $i + 1,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    private function seedDekorItemMaster(): void
    {
        $items = [
            ['BDG', 'Budget'],
            ['CRS', 'Corsase'],
            ['BNG_PTI', 'Bunga Atas Peti Standar'],
            ['BNG_MJ', 'Bunga Hias Meja'],
            ['BNG_MSA', 'Bunga Misa'],
            ['BNG_SLB', 'Bunga Salib'],
            ['BNG_SDM', 'Bunga Sedap Malam'],
            ['BNG_TBR', 'Bunga Tabur'],
            ['KRJ_HIS', 'Keranjang Hias'],
            ['DKR', 'Dekorasi'],
            ['CVR_KRS', 'Cover Kursi'],
            ['TMN', 'Taman (Tanaman Pot)'],
            ['HNB', 'Hanbouquet'],
            ['KY_PTI', 'Kayu Bunga Atas Peti'],
            ['KY_SLB', 'Kayu Bunga Salib'],
            ['MKP', 'Mika Panjang 8x20'],
            ['MKK', 'Mika Kecil 8x10'],
            ['GLS_VAS', 'Gelas/Vas'],
            ['OAS', 'Oasis'],
        ];

        foreach ($items as $i => [$code, $name]) {
            DB::table('dekor_item_master')->insertOrIgnore([
                'id' => Str::uuid(),
                'item_code' => $code,
                'item_name' => $name,
                'default_unit' => 'set',
                'sort_order' => $i + 1,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    private function seedDeathCertDocMaster(): void
    {
        $items = [
            ['SURAT_PENGANTAR_RT', 'Surat Pengantar RT/RW', true],
            ['KTP_MENINGGAL', 'KTP Almarhum', true],
            ['KK_MENINGGAL', 'KK Almarhum', true],
            ['SURAT_KEMATIAN_RS', 'Surat Kematian dari RS/Dokter', true],
            ['SURAT_KEMATIAN_KEL', 'Surat Kematian dari Kelurahan', true],
            ['AKTE_LAHIR', 'Akte Lahir Almarhum', true],
            ['SURAT_GANTI_NAMA', 'Surat Ganti Nama Almarhum', false],
            ['SURAT_NIKAH', 'Surat Nikah', true],
            ['AKTE_KEMATIAN_PASANGAN', 'Akte Kematian Pasangan', false],
            ['GANTI_NAMA_PASANGAN', 'Surat Ganti Nama Pasangan', false],
            ['SBKRI', 'SBKRI', false],
            ['POA_STMD', 'Surat POA / STMD', false],
            ['FC_KTP_KUASA', 'Fotocopy KTP Kuasa', true],
            ['FC_KK_KUASA', 'Fotocopy KK Kuasa', true],
            ['FC_AKTE_LAHIR_KUASA', 'Fotocopy Akte Lahir Kuasa', false],
            ['FC_GANTI_NAMA_KUASA', 'Fotocopy Ganti Nama Kuasa', false],
            ['FC_KTP_ANAK', 'Fotocopy KTP Anak', false],
            ['SURAT_KUASA', 'Surat Kuasa', true],
            ['AKTE_KEMATIAN_JADI', 'Akte Kematian (Jadi)', true],
            ['KK_TERBARU', 'KK Terbaru', true],
            ['KTP_TERBARU_PASANGAN', 'KTP Terbaru Pasangan', false],
        ];

        foreach ($items as $i => [$code, $name, $required]) {
            DB::table('death_cert_doc_master')->insertOrIgnore([
                'id' => Str::uuid(),
                'doc_code' => $code,
                'doc_name' => $name,
                'sort_order' => $i + 1,
                'is_required' => $required,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    private function seedCoffinStageMaster(): void
    {
        $melaminStages = [
            'Amplas Tank', 'Amplas 100', 'Amplas 240', 'Filler',
            'Amplas 240 + Service', 'Sending', 'Amplas 240', 'Sending + Warna',
            'Amplas 360', 'Gloss',
        ];

        $ducoStages = [
            'Amplas Tank', 'Epoxy', 'Dempul', 'Amplas 100', 'Amplas 240',
            'Epoxy', 'Service + Amplas 360', 'Cat', 'Amplas 1000', 'Gloss', 'Compound',
        ];

        foreach ($melaminStages as $i => $name) {
            DB::table('coffin_stage_master')->insertOrIgnore([
                'id' => Str::uuid(),
                'finishing_type' => 'melamin',
                'stage_number' => $i + 1,
                'stage_name' => $name,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        foreach ($ducoStages as $i => $name) {
            DB::table('coffin_stage_master')->insertOrIgnore([
                'id' => Str::uuid(),
                'finishing_type' => 'duco',
                'stage_number' => $i + 1,
                'stage_name' => $name,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    private function seedCoffinQcCriteriaMaster(): void
    {
        $criteria = [
            ['MENGKILAP', 'Mengkilap', null],
            ['WARNA_RATA', 'Warna Rata', null],
            ['TIDAK_MELELEH', 'Tidak Meleleh', 'duco'],
            ['SAMBUNGAN_RAPI', 'Sambungan Rapi', null],
            ['SERAT_TIDAK_BERLUBANG', 'Serat Tidak Berlubang', null],
            ['MODEL_LENGKUNG_RAPI', 'Model Lengkung Rapi', null],
        ];

        foreach ($criteria as $i => [$code, $name, $type]) {
            DB::table('coffin_qc_criteria_master')->insertOrIgnore([
                'id' => Str::uuid(),
                'criteria_code' => $code,
                'criteria_name' => $name,
                'finishing_type' => $type,
                'sort_order' => $i + 1,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }
}
