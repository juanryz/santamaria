<?php
namespace App\Exports;

use App\Models\Order;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;

class OrderReportExport implements FromCollection, WithHeadings, WithMapping
{
    public function __construct(private ?string $from, private ?string $to) {}

    public function collection()
    {
        return Order::with(['consumer:id,name', 'package:id,name'])
            ->when($this->from, fn($q) => $q->whereDate('created_at', '>=', $this->from))
            ->when($this->to,   fn($q) => $q->whereDate('created_at', '<=', $this->to))
            ->orderBy('created_at', 'desc')
            ->get();
    }

    public function headings(): array
    {
        return ['Kode Order', 'Konsumen', 'Almarhum', 'Paket', 'Total', 'Metode Bayar', 'Tgl Bayar', 'Status', 'Tgl Order'];
    }

    public function map($order): array
    {
        return [
            $order->order_code,
            $order->consumer?->name,
            $order->deceased_name,
            $order->package?->name,
            $order->total_amount,
            $order->payment_method,
            $order->paid_at?->format('Y-m-d'),
            $order->status,
            $order->created_at->format('Y-m-d'),
        ];
    }
}
