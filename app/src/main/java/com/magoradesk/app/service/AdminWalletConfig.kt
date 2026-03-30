package com.magoradesk.app.service

import com.magoradesk.app.model.CryptoCurrency
import com.magoradesk.app.model.WalletAddress

/**
 * Configuration for admin wallets that receive the 4% fee from all
 * trades and deposits. Each supported cryptocurrency has its own
 * admin wallet address.
 *
 * IMPORTANT: Replace the placeholder addresses with real admin wallet
 * addresses before deploying to production.
 */
object AdminWalletConfig {

    /**
     * Default admin wallet addresses for each supported cryptocurrency.
     * These must be replaced with actual wallet addresses before production use.
     */
    private val adminWallets = mutableMapOf(
        CryptoCurrency.BITCOIN to "YOUR_BITCOIN_ADMIN_WALLET_ADDRESS",
        CryptoCurrency.MONERO to "YOUR_MONERO_ADMIN_WALLET_ADDRESS",
        CryptoCurrency.LITECOIN to "YOUR_LITECOIN_ADMIN_WALLET_ADDRESS",
        CryptoCurrency.ETHEREUM to "YOUR_ETHEREUM_ADMIN_WALLET_ADDRESS"
    )

    /**
     * Gets the admin wallet address for the specified cryptocurrency.
     *
     * @param currency The cryptocurrency
     * @return The admin wallet address
     * @throws IllegalStateException if no wallet is configured for the currency
     */
    fun getAdminWalletAddress(currency: CryptoCurrency): String {
        return adminWallets[currency]
            ?: throw IllegalStateException("No admin wallet configured for ${currency.displayName}")
    }

    /**
     * Sets the admin wallet address for a specific cryptocurrency.
     * Used during app configuration.
     *
     * @param currency The cryptocurrency
     * @param address The wallet address
     */
    fun setAdminWalletAddress(currency: CryptoCurrency, address: String) {
        require(address.isNotBlank()) { "Wallet address must not be blank" }
        adminWallets[currency] = address
    }

    /**
     * Returns all configured admin wallet addresses.
     */
    fun getAllAdminWallets(): Map<CryptoCurrency, String> {
        return adminWallets.toMap()
    }

    /**
     * Validates all admin wallet addresses are configured.
     *
     * @return List of currencies with missing/placeholder wallet addresses
     */
    fun getUnconfiguredWallets(): List<CryptoCurrency> {
        return adminWallets.filter { (_, address) ->
            address.isBlank() || address.startsWith("YOUR_")
        }.keys.toList()
    }

    /**
     * Creates AdminFeeService instances for each configured cryptocurrency.
     */
    fun createFeeServices(): Map<CryptoCurrency, AdminFeeService> {
        return adminWallets.map { (currency, address) ->
            currency to AdminFeeService(
                adminWalletAddress = address,
                feePercentage = AdminFeeService.DEFAULT_FEE_PERCENTAGE
            )
        }.toMap()
    }

    /**
     * Returns WalletAddress objects for all configured admin wallets.
     */
    fun getAdminWalletAddresses(): List<WalletAddress> {
        return adminWallets.map { (currency, address) ->
            WalletAddress(
                address = address,
                currency = currency,
                label = "Admin Fee Wallet (${currency.symbol})"
            )
        }
    }
}
