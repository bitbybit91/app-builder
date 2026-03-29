<?php

namespace App\Controllers;

use App\Core\View;
use App\Core\Auth;
use App\Models\Trade;

class HomeController
{
    public function index(): void
    {
        $recentTrades = Trade::listAll(6);
        $buyCount = Trade::countByType('buy');
        $sellCount = Trade::countByType('sell');

        View::render('pages/home', [
            'title' => 'Capital Monero — Peer-to-Peer Monero Trading',
            'recentTrades' => $recentTrades,
            'buyCount' => $buyCount,
            'sellCount' => $sellCount,
            'user' => Auth::user(),
        ]);
    }
}
