<?php

namespace App\Controllers;

use App\Core\View;
use App\Core\Auth;
use App\Core\CSRF;
use App\Models\Trade;
use App\Models\TradeResponse;

class DashboardController
{
    public function index(): void
    {
        Auth::requireLogin();
        $user = Auth::user();
        $myTrades = Trade::listByUser($user['id']);
        $myResponses = TradeResponse::listByUser($user['id']);

        View::render('pages/dashboard', [
            'title' => 'Dashboard — Capital Monero',
            'user' => $user,
            'myTrades' => $myTrades,
            'myResponses' => $myResponses,
        ]);
    }

    public function myTrades(): void
    {
        Auth::requireLogin();
        $user = Auth::user();
        $trades = Trade::listByUser($user['id']);

        View::render('pages/dashboard_trades', [
            'title' => 'My Trades — Capital Monero',
            'user' => $user,
            'trades' => $trades,
        ]);
    }

    public function settings(): void
    {
        Auth::requireLogin();

        View::render('pages/dashboard_settings', [
            'title' => 'Settings — Capital Monero',
            'user' => Auth::user(),
        ]);
    }

    public function updateSettings(): void
    {
        Auth::requireLogin();
        CSRF::verify();

        $bio = trim($_POST['bio'] ?? '');
        \App\Models\User::updateProfile(Auth::id(), $bio);

        $_SESSION['flash_success'] = 'Settings updated successfully!';
        header('Location: /dashboard/settings');
        exit;
    }
}
