<?php

namespace App\Controllers;

use App\Core\View;
use App\Core\Auth;
use App\Core\CSRF;
use App\Core\Validator;
use App\Models\User;

class AuthController
{
    public function registerForm(): void
    {
        if (Auth::check()) {
            header('Location: /dashboard');
            exit;
        }

        View::render('pages/register', [
            'title' => 'Register — Capital Monero',
            'user' => null,
        ]);
    }

    public function register(): void
    {
        CSRF::verify();

        $validator = new Validator();
        $validator
            ->required('username', 'Username')
            ->minLength('username', 'Username', 3)
            ->maxLength('username', 'Username', 30)
            ->unique('username', 'Username', 'users', 'username')
            ->required('email', 'Email')
            ->email('email', 'Email')
            ->unique('email', 'Email', 'users', 'email')
            ->required('password', 'Password')
            ->minLength('password', 'Password', 8)
            ->match('password', 'password_confirm', 'Passwords');

        if (!$validator->passes()) {
            $_SESSION['flash_error'] = $validator->firstError();
            $_SESSION['form_data'] = $_POST;
            header('Location: /register');
            exit;
        }

        $username = trim($_POST['username']);
        $email = trim($_POST['email']);
        $passwordHash = password_hash($_POST['password'], PASSWORD_DEFAULT);

        $userId = User::create($username, $email, $passwordHash);
        Auth::login($userId);

        $_SESSION['flash_success'] = 'Welcome to Capital Monero! Your account has been created.';
        header('Location: /dashboard');
        exit;
    }

    public function loginForm(): void
    {
        if (Auth::check()) {
            header('Location: /dashboard');
            exit;
        }

        View::render('pages/login', [
            'title' => 'Login — Capital Monero',
            'user' => null,
        ]);
    }

    public function login(): void
    {
        CSRF::verify();

        $username = trim($_POST['username'] ?? '');
        $password = $_POST['password'] ?? '';

        if ($username === '' || $password === '') {
            $_SESSION['flash_error'] = 'Please enter your username and password.';
            header('Location: /login');
            exit;
        }

        $user = User::findByUsername($username);
        if (!$user || !password_verify($password, $user['password_hash'])) {
            $_SESSION['flash_error'] = 'Invalid username or password.';
            header('Location: /login');
            exit;
        }

        Auth::login((int)$user['id']);
        $_SESSION['flash_success'] = 'Welcome back, ' . htmlspecialchars($user['username']) . '!';
        header('Location: /dashboard');
        exit;
    }

    public function logout(): void
    {
        Auth::logout();
        session_start();
        $_SESSION['flash_success'] = 'You have been logged out.';
        header('Location: /');
        exit;
    }
}
