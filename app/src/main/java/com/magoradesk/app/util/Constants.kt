package com.magoradesk.app.util

/**
 * Constants used throughout the application.
 */
object Constants {

    /**
     * Admin fee percentage: 4% of all trades and deposits.
     */
    const val ADMIN_FEE_PERCENTAGE = 0.04

    /**
     * Display string for the admin fee.
     */
    const val ADMIN_FEE_DISPLAY = "4%"

    /**
     * Shared preferences file name.
     */
    const val PREFS_NAME = "magoradesk_prefs"

    /**
     * Keys for shared preferences.
     */
    object PrefKeys {
        const val ADMIN_WALLET_BTC = "admin_wallet_btc"
        const val ADMIN_WALLET_XMR = "admin_wallet_xmr"
        const val ADMIN_WALLET_LTC = "admin_wallet_ltc"
        const val ADMIN_WALLET_ETH = "admin_wallet_eth"
        const val THEME_MODE = "theme_mode"
        const val NOTIFICATIONS_ENABLED = "notifications_enabled"
        const val DEFAULT_CURRENCY = "default_currency"
        const val DEFAULT_FIAT = "default_fiat"
    }

    /**
     * API endpoints.
     */
    object Api {
        const val BASE_URL = "https://api.magoradesk.com/"
        const val TRADES = "api/v1/trades"
        const val DEPOSITS = "api/v1/deposits"
        const val WALLET = "api/v1/wallet"
        const val OFFERS = "api/v1/offers"
    }

    /**
     * Navigation destinations.
     */
    object Nav {
        const val TRADE_LIST = "trade_list"
        const val TRADE_DETAIL = "trade_detail"
        const val CREATE_OFFER = "create_offer"
        const val DEPOSIT = "deposit"
        const val WALLET = "wallet"
        const val SETTINGS = "settings"
    }
}
