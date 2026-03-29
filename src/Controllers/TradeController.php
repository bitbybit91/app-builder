<?php

namespace App\Controllers;

use App\Core\View;
use App\Core\Auth;
use App\Core\CSRF;
use App\Core\Validator;
use App\Models\Trade;
use App\Models\TradeResponse;
use App\Models\Message;

class TradeController
{
    public function index(): void
    {
        $search = trim($_GET['q'] ?? '');
        if ($search !== '') {
            $trades = Trade::search($search);
        } else {
            $page = max(1, (int)($_GET['page'] ?? 1));
            $limit = 20;
            $offset = ($page - 1) * $limit;
            $trades = Trade::listAll($limit, $offset);
        }

        View::render('pages/trades', [
            'title' => 'All Trades — Capital Monero',
            'trades' => $trades,
            'search' => $search,
            'user' => Auth::user(),
        ]);
    }

    public function buyListings(): void
    {
        $page = max(1, (int)($_GET['page'] ?? 1));
        $limit = 20;
        $offset = ($page - 1) * $limit;
        $trades = Trade::listByType('sell', $limit, $offset);

        View::render('pages/trades', [
            'title' => 'Buy Monero — Capital Monero',
            'trades' => $trades,
            'heading' => 'Buy Monero',
            'subtitle' => 'Browse offers from sellers',
            'search' => '',
            'user' => Auth::user(),
        ]);
    }

    public function sellListings(): void
    {
        $page = max(1, (int)($_GET['page'] ?? 1));
        $limit = 20;
        $offset = ($page - 1) * $limit;
        $trades = Trade::listByType('buy', $limit, $offset);

        View::render('pages/trades', [
            'title' => 'Sell Monero — Capital Monero',
            'trades' => $trades,
            'heading' => 'Sell Monero',
            'subtitle' => 'Browse offers from buyers',
            'search' => '',
            'user' => Auth::user(),
        ]);
    }

    public function createForm(): void
    {
        Auth::requireLogin();

        View::render('pages/trade_create', [
            'title' => 'Create Trade — Capital Monero',
            'user' => Auth::user(),
        ]);
    }

    public function create(): void
    {
        Auth::requireLogin();
        CSRF::verify();

        $validator = new Validator();
        $validator
            ->required('type', 'Trade type')
            ->required('title', 'Title')
            ->minLength('title', 'Title', 5)
            ->maxLength('title', 'Title', 100)
            ->required('amount_min', 'Minimum amount')
            ->numeric('amount_min', 'Minimum amount')
            ->min('amount_min', 'Minimum amount', 1)
            ->required('amount_max', 'Maximum amount')
            ->numeric('amount_max', 'Maximum amount')
            ->required('payment_method', 'Payment method');

        if (!$validator->passes()) {
            $_SESSION['flash_error'] = $validator->firstError();
            $_SESSION['form_data'] = $_POST;
            header('Location: /trades/create');
            exit;
        }

        $type = $_POST['type'];
        if (!in_array($type, ['buy', 'sell'], true)) {
            $_SESSION['flash_error'] = 'Invalid trade type.';
            header('Location: /trades/create');
            exit;
        }

        $tradeId = Trade::create([
            'user_id' => Auth::id(),
            'type' => $type,
            'title' => trim($_POST['title']),
            'description' => trim($_POST['description'] ?? ''),
            'amount_min' => (float)$_POST['amount_min'],
            'amount_max' => (float)$_POST['amount_max'],
            'price_per_xmr' => !empty($_POST['price_per_xmr']) ? (float)$_POST['price_per_xmr'] : null,
            'currency' => $_POST['currency'] ?? 'USD',
            'payment_method' => trim($_POST['payment_method']),
            'location' => trim($_POST['location'] ?? ''),
        ]);

        $_SESSION['flash_success'] = 'Trade created successfully!';
        header('Location: /trades/view?id=' . $tradeId);
        exit;
    }

    public function view(): void
    {
        $id = (int)($_GET['id'] ?? 0);
        $trade = Trade::findById($id);

        if (!$trade) {
            http_response_code(404);
            View::render('pages/404', ['title' => 'Trade Not Found', 'user' => Auth::user()]);
            return;
        }

        $responses = TradeResponse::listByTrade($id);

        $messages = [];
        $responseId = (int)($_GET['response'] ?? 0);
        if ($responseId > 0) {
            $messages = Message::listByTradeResponse($responseId);
        }

        View::render('pages/trade_view', [
            'title' => htmlspecialchars($trade['title']) . ' — Capital Monero',
            'trade' => $trade,
            'responses' => $responses,
            'messages' => $messages,
            'activeResponseId' => $responseId,
            'user' => Auth::user(),
        ]);
    }

    public function respond(): void
    {
        Auth::requireLogin();
        CSRF::verify();

        $tradeId = (int)($_POST['trade_id'] ?? 0);
        $trade = Trade::findById($tradeId);

        if (!$trade || $trade['status'] !== 'open') {
            $_SESSION['flash_error'] = 'Trade not found or not available.';
            header('Location: /trades');
            exit;
        }

        if ($trade['user_id'] === Auth::id()) {
            $_SESSION['flash_error'] = 'You cannot respond to your own trade.';
            header('Location: /trades/view?id=' . $tradeId);
            exit;
        }

        $amount = (float)($_POST['amount'] ?? 0);
        $message = trim($_POST['message'] ?? '');

        if ($amount <= 0) {
            $_SESSION['flash_error'] = 'Please enter a valid amount.';
            header('Location: /trades/view?id=' . $tradeId);
            exit;
        }

        $responseId = TradeResponse::create($tradeId, Auth::id(), $amount, $message);

        $_SESSION['flash_success'] = 'Your response has been submitted!';
        header('Location: /trades/view?id=' . $tradeId);
        exit;
    }

    public function sendMessage(): void
    {
        Auth::requireLogin();
        CSRF::verify();

        $responseId = (int)($_POST['response_id'] ?? 0);
        $tradeId = (int)($_POST['trade_id'] ?? 0);
        $body = trim($_POST['body'] ?? '');

        if ($responseId <= 0 || $body === '') {
            $_SESSION['flash_error'] = 'Please enter a message.';
            header('Location: /trades/view?id=' . $tradeId . '&response=' . $responseId);
            exit;
        }

        $response = TradeResponse::findById($responseId);
        if (!$response) {
            $_SESSION['flash_error'] = 'Response not found.';
            header('Location: /trades');
            exit;
        }

        Message::create($responseId, Auth::id(), $body);

        $_SESSION['flash_success'] = 'Message sent!';
        header('Location: /trades/view?id=' . $tradeId . '&response=' . $responseId);
        exit;
    }
}
