package com.magoradesk.app.service

import com.magoradesk.app.model.CryptoCurrency
import com.magoradesk.app.model.FeeBreakdown
import java.math.BigDecimal
import java.math.RoundingMode

/**
 * Service responsible for calculating and managing the 4% admin fee
 * that is applied to all cryptocurrency trades and deposits.
 *
 * The admin fee is deducted from every transaction and sent to the
 * configured admin wallet address. This ensures the platform receives
 * its revenue share from all trading activity.
 *
 * Fee structure:
 * - 4% of the total trade amount is deducted as the admin fee
 * - The remaining 96% goes to the intended recipient
 * - The fee is calculated using BigDecimal for precision
 * - Rounding uses HALF_UP mode to ensure fairness
 */
class AdminFeeService(
    private val adminWalletAddress: String,
    private val feePercentage: BigDecimal = DEFAULT_FEE_PERCENTAGE
) {

    companion object {
        /**
         * Default admin fee percentage: 4% (0.04)
         * 4% of all trades and deposits are sent to the admin wallet.
         */
        val DEFAULT_FEE_PERCENTAGE: BigDecimal = BigDecimal("0.04")

        /**
         * Human-readable fee percentage for display purposes.
         */
        const val FEE_DISPLAY_PERCENTAGE = "4%"

        /**
         * Maximum allowed fee percentage (safety check).
         */
        val MAX_FEE_PERCENTAGE: BigDecimal = BigDecimal("0.10")

        /**
         * Minimum transaction amount to apply fee (to avoid dust).
         */
        val MIN_AMOUNT_FOR_FEE: BigDecimal = BigDecimal("0.00000001")
    }

    init {
        require(adminWalletAddress.isNotBlank()) {
            "Admin wallet address must not be blank"
        }
        require(feePercentage > BigDecimal.ZERO && feePercentage <= MAX_FEE_PERCENTAGE) {
            "Fee percentage must be between 0 and ${MAX_FEE_PERCENTAGE.toPlainString()}"
        }
    }

    /**
     * Calculates the fee breakdown for a given amount and cryptocurrency.
     *
     * @param amount The total transaction amount
     * @param currency The cryptocurrency being transacted
     * @return FeeBreakdown containing the admin fee and recipient amounts
     * @throws IllegalArgumentException if amount is negative
     */
    fun calculateFee(amount: BigDecimal, currency: CryptoCurrency): FeeBreakdown {
        require(amount >= BigDecimal.ZERO) {
            "Transaction amount cannot be negative"
        }

        if (amount < MIN_AMOUNT_FOR_FEE) {
            return FeeBreakdown(
                originalAmount = amount,
                adminFeeAmount = BigDecimal.ZERO,
                recipientAmount = amount,
                feePercentage = feePercentage,
                currency = currency
            )
        }

        val adminFeeAmount = amount
            .multiply(feePercentage)
            .setScale(currency.decimals, RoundingMode.HALF_UP)

        val recipientAmount = amount
            .subtract(adminFeeAmount)
            .setScale(currency.decimals, RoundingMode.HALF_UP)

        return FeeBreakdown(
            originalAmount = amount,
            adminFeeAmount = adminFeeAmount,
            recipientAmount = recipientAmount,
            feePercentage = feePercentage,
            currency = currency
        )
    }

    /**
     * Calculates the admin fee amount for a trade.
     *
     * @param tradeAmount The total trade amount in cryptocurrency
     * @param currency The cryptocurrency being traded
     * @return The fee amount to be sent to the admin wallet
     */
    fun calculateTradeFee(tradeAmount: BigDecimal, currency: CryptoCurrency): BigDecimal {
        return calculateFee(tradeAmount, currency).adminFeeAmount
    }

    /**
     * Calculates the admin fee amount for a deposit.
     *
     * @param depositAmount The total deposit amount
     * @param currency The cryptocurrency being deposited
     * @return The fee amount to be sent to the admin wallet
     */
    fun calculateDepositFee(depositAmount: BigDecimal, currency: CryptoCurrency): BigDecimal {
        return calculateFee(depositAmount, currency).adminFeeAmount
    }

    /**
     * Returns the net amount the recipient receives after the 4% admin fee.
     *
     * @param amount The total amount
     * @param currency The cryptocurrency
     * @return The amount after deducting the admin fee
     */
    fun getNetAmount(amount: BigDecimal, currency: CryptoCurrency): BigDecimal {
        return calculateFee(amount, currency).recipientAmount
    }

    /**
     * Returns the admin wallet address where fees are sent.
     */
    fun getAdminWalletAddress(): String = adminWalletAddress

    /**
     * Returns the configured fee percentage.
     */
    fun getFeePercentage(): BigDecimal = feePercentage

    /**
     * Returns the fee percentage as a human-readable string.
     */
    fun getFeePercentageDisplay(): String {
        return "${feePercentage.multiply(BigDecimal(100)).stripTrailingZeros().toPlainString()}%"
    }

    /**
     * Validates that the admin wallet address is properly configured
     * for the given cryptocurrency.
     *
     * @param currency The cryptocurrency to validate the wallet for
     * @return true if the wallet address appears valid for the currency
     */
    fun isWalletConfiguredFor(currency: CryptoCurrency): Boolean {
        if (adminWalletAddress.isBlank()) return false
        return when (currency) {
            CryptoCurrency.BITCOIN -> adminWalletAddress.length in 26..62
            CryptoCurrency.MONERO -> adminWalletAddress.length in 95..106
            CryptoCurrency.LITECOIN -> adminWalletAddress.length in 26..34
            CryptoCurrency.ETHEREUM -> adminWalletAddress.length == 42 &&
                    adminWalletAddress.startsWith("0x")
        }
    }
}
