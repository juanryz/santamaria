<?php
namespace App\Exports;

use App\Models\FinancialTransaction;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;

class TransactionExport implements FromCollection, WithHeadings, WithMapping
{
    public function __construct(private ?string $from, private ?string $to, private ?string $category) {}

    public function collection()
    {
        return FinancialTransaction::active()
            ->with('recordedBy:id,name')
            ->when($this->from,     fn($q) => $q->whereDate('transaction_date', '>=', $this->from))
            ->when($this->to,       fn($q) => $q->whereDate('transaction_date', '<=', $this->to))
            ->when($this->category, fn($q) => $q->where('category', $this->category))
            ->orderBy('transaction_date', 'desc')
            ->get();
    }

    public function headings(): array
    {
        return ['Tanggal', 'Tipe', 'Kategori', 'Arah', 'Nominal (IDR)', 'Deskripsi', 'Dicatat oleh'];
    }

    public function map($tx): array
    {
        return [
            $tx->transaction_date->format('Y-m-d'),
            $tx->transaction_type,
            $tx->category,
            $tx->direction === 'in' ? 'Masuk' : 'Keluar',
            $tx->amount,
            $tx->description,
            $tx->recordedBy?->name,
        ];
    }
}
