<?php
namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use App\Services\FinancialTransactionService;

class FinanceDashboardController extends Controller
{
    public function __construct(private FinancialTransactionService $service) {}

    public function index()
    {
        return response()->json([
            'success' => true,
            'data'    => $this->service->getDashboardData(),
        ]);
    }
}
