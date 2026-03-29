<?php

namespace App\Controllers;

use App\Core\View;
use App\Core\Auth;
use App\Core\CSRF;
use App\Core\Database;
use App\Core\Validator;

class PageController
{
    public function about(): void
    {
        View::render('pages/about', [
            'title' => 'About — Capital Monero',
            'user' => Auth::user(),
        ]);
    }

    public function faq(): void
    {
        View::render('pages/faq', [
            'title' => 'FAQ — Capital Monero',
            'user' => Auth::user(),
        ]);
    }

    public function terms(): void
    {
        View::render('pages/terms', [
            'title' => 'Terms of Service — Capital Monero',
            'user' => Auth::user(),
        ]);
    }

    public function contact(): void
    {
        View::render('pages/contact', [
            'title' => 'Contact — Capital Monero',
            'user' => Auth::user(),
        ]);
    }

    public function contactSubmit(): void
    {
        CSRF::verify();

        $validator = new Validator();
        $validator
            ->required('name', 'Name')
            ->required('email', 'Email')
            ->email('email', 'Email')
            ->required('subject', 'Subject')
            ->required('message', 'Message')
            ->minLength('message', 'Message', 10);

        if (!$validator->passes()) {
            $_SESSION['flash_error'] = $validator->firstError();
            $_SESSION['form_data'] = $_POST;
            header('Location: /contact');
            exit;
        }

        Database::query(
            'INSERT INTO contact_messages (name, email, subject, message) VALUES (?, ?, ?, ?)',
            [
                trim($_POST['name']),
                trim($_POST['email']),
                trim($_POST['subject']),
                trim($_POST['message']),
            ]
        );

        $_SESSION['flash_success'] = 'Thank you for your message! We will get back to you shortly.';
        header('Location: /contact');
        exit;
    }
}
