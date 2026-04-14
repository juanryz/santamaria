<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Artisan;

class RefreshCurrentKpi extends Command
{
    protected $signature   = 'kpi:refresh-current-period';
    protected $description = 'Refresh KPI scores for the current open period (lighter than full monthly calc).';

    public function handle(): void
    {
        Artisan::call('kpi:calculate-monthly');
        $this->info('Current period KPI refreshed.');
    }
}
