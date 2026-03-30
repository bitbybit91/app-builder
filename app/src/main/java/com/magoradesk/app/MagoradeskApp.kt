package com.magoradesk.app

import android.app.Application
import com.magoradesk.app.service.AdminFeeService
import com.magoradesk.app.service.AdminWalletConfig
import com.magoradesk.app.service.DepositService
import com.magoradesk.app.service.TradeService
import com.magoradesk.app.service.TransactionService
import com.magoradesk.app.model.CryptoCurrency

/**
 * Main Application class for Magoradesk.
 *
 * Initializes core services including the 4% admin fee service
 * that processes fees on all trades and deposits.
 */
class MagoradeskApp : Application() {

    lateinit var adminFeeServices: Map<CryptoCurrency, AdminFeeService>
        private set

    lateinit var tradeService: TradeService
        private set

    lateinit var depositService: DepositService
        private set

    lateinit var transactionService: TransactionService
        private set

    override fun onCreate() {
        super.onCreate()
        instance = this
        initializeServices()
    }

    private fun initializeServices() {
        // Validate admin wallet configuration
        val unconfigured = AdminWalletConfig.getUnconfiguredWallets()
        if (unconfigured.isNotEmpty()) {
            android.util.Log.w(
                "MagoradeskApp",
                "Admin wallets not configured for: ${unconfigured.joinToString { it.symbol }}. " +
                "Fees will not be collected until real wallet addresses are set in Settings."
            )
        }

        // Initialize admin fee services for all supported cryptocurrencies
        adminFeeServices = AdminWalletConfig.createFeeServices()

        // Use the Bitcoin admin fee service as the default
        val defaultFeeService = adminFeeServices[CryptoCurrency.BITCOIN]
            ?: AdminFeeService(
                adminWalletAddress = AdminWalletConfig.getAdminWalletAddress(CryptoCurrency.BITCOIN)
            )

        tradeService = TradeService(defaultFeeService)
        depositService = DepositService(defaultFeeService)
        transactionService = TransactionService(defaultFeeService)
    }

    /**
     * Gets the AdminFeeService for a specific cryptocurrency.
     */
    fun getFeeService(currency: CryptoCurrency): AdminFeeService {
        return adminFeeServices[currency]
            ?: throw IllegalStateException("No fee service configured for ${currency.displayName}")
    }

    companion object {
        lateinit var instance: MagoradeskApp
            private set
    }
}
