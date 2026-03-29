<?php

namespace App\Core;

class Router
{
    private array $routes = [];

    public function get(string $path, array $handler): void
    {
        $this->routes['GET'][$path] = $handler;
    }

    public function post(string $path, array $handler): void
    {
        $this->routes['POST'][$path] = $handler;
    }

    public function dispatch(string $method, string $uri): void
    {
        $uri = rtrim($uri, '/') ?: '/';

        if (isset($this->routes[$method][$uri])) {
            [$class, $action] = $this->routes[$method][$uri];
            $controller = new $class();
            $controller->$action();
            return;
        }

        http_response_code(404);
        View::render('pages/404', ['title' => 'Page Not Found']);
    }
}
