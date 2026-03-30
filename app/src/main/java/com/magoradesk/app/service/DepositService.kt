package com.magoradesk.app.service

import com.magoradesk.app.model.*
import java.math.BigDecimal
import java.util.UUID

/**
 * Service responsible for processing cryptocurrency deposits with the 4% admin fee.
 *
 * When a deposit is received:
 * 1. The deposit is detected on the blockchain
 * 2. After required confirmations, the deposit is processed
 * 3. 4% of the deposit is sent to the admin wallet
 * 4. The remaining 96% is credited to the user's account
 */
class DepositService(
    private val adminFeeService: AdminFeeService
) {

    /**
     * Processes an incoming deposit, calculating the 4% admin fee.
     *
     * @param amount The total deposit amount
     * @param currency The cryptocurrency being deposited
     * @param depositAddress The address where the deposit was received
     * @return The created Deposit with fee calculations applied
     */
    fun processDeposit(
        amount: BigDecimal,
        currency: CryptoCurrency,
        depositAddress: String
    ): Deposit {
        require(amount > BigDecimal.ZERO) { "Deposit amount must be positive" }
        require(depositAddress.isNotBlank()) { "Deposit address must not be blank" }

        val feeBreakdown = adminFeeService.calculateFee(amount, currency)

        return Deposit(
            id = UUID.randomUUID().toString(),
            currency = currency,
            amount = amount,
            adminFeeAmount = feeBreakdown.adminFeeAmount,
            netAmount = feeBreakdown.recipientAmount,
            depositAddress = depositAddress,
            adminWalletAddress = adminFeeService.getAdminWalletAddress(),
            requiredConfirmations = getRequiredConfirmations(currency)
        )
    }

    /**
     * Processes the fee transfer for a confirmed deposit.
     * Sends 4% to the admin wallet.
     *
     * @param deposit The confirmed deposit
     * @return CryptoTransfer details for the admin fee
     */
    fun processDepositFeeTransfer(deposit: Deposit): CryptoTransfer {
        require(deposit.isConfirmed()) { "Deposit must be confirmed before fee transfer" }

        return CryptoTransfer(
            amount = deposit.adminFeeAmount,
            currency = deposit.currency,
            toAddress = deposit.adminWalletAddress,
            purpose = "Admin fee (${adminFeeService.getFeePercentageDisplay()}) for deposit ${deposit.id}"
        )
    }

    /**
     * Calculates the fee preview for a deposit amount.
     *
     * @param amount The deposit amount
     * @param currency The cryptocurrency
     * @return FeeBreakdown with the fee details
     */
    fun previewDepositFee(amount: BigDecimal, currency: CryptoCurrency): FeeBreakdown {
        return adminFeeService.calculateFee(amount, currency)
    }

    /**
     * Returns the number of confirmations required for a deposit
     * based on the cryptocurrency type.
     */
    private fun getRequiredConfirmations(currency: CryptoCurrency): Int {
        return when (currency) {
            CryptoCurrency.BITCOIN -> 3
            CryptoCurrency.MONERO -> 10
            CryptoCurrency.LITECOIN -> 6
            CryptoCurrency.ETHEREUM -> 12
        }
    }
}
