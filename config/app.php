<?php

return [
    'name' => 'Capital Monero',
    'url' => 'https://capitalmonero.com',
    'timezone' => 'UTC',
    'debug' => false,

    'db' => [
        'driver' => 'sqlite',
        'path' => __DIR__ . '/../database/capitalmonero.sqlite',
    ],

    'session' => [
        'lifetime' => 7200,
        'name' => 'capitalmonero_session',
    ],

    'currency' => [
        'default_fiat' => 'USD',
        'supported_fiat' => ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'CHF'],
    ],

    'trade' => [
        'min_amount' => 10,
        'max_amount' => 100000,
        'escrow_fee_percent' => 1.0,
    ],
];
