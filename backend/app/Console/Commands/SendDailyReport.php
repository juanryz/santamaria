<?php

namespace App\Console\Commands;

use App\Services\AI\DailyReportService;
use Illuminate\Console\Command;

class SendDailyReport extends Command
{
    protected $signature = 'report:daily';
    protected $description = 'Generate and send daily AI report to owner';

    public function handle(DailyReportService $service)
    {
        $this->info('Generating daily report...');
        $service->generateAndSend();
        $this->info('Daily report sent.');
    }
}
