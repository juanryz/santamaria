<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Flutter APK akan akses API dari origin Android (biasanya null-origin).
    | Set allowed_origins = ['*'] untuk development; di production kita
    | batasi hanya domain consumer-facing web (kalau ada) & app domain.
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie', 'storage/*'],

    'allowed_methods' => ['*'],

    /*
    | Daftar origin yg boleh akses.
    | Flutter APK kirim request tanpa Origin header, jadi wildcard OK untuk dev.
    | Production: ganti ke domain publik (landing page, admin web, dll).
    */
    'allowed_origins' => ['*'],

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    /*
    | Set true kalau pakai cookie-based auth (session).
    | Flutter pakai token (sanctum) jadi false OK.
    | Kalau true, allowed_origins tidak boleh '*'.
    */
    'supports_credentials' => false,

];
