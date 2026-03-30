package com.magoradesk.app.model

import java.math.BigDecimal
import java.math.RoundingMode

/**
 * Represents a cryptocurrency type supported by the application.
 */
enum class CryptoCurrency(val symbol: String, val displayName: String, val decimals: Int) {
    BITCOIN("BTC", "Bitcoin", 8),
    MONERO("XMR", "Monero", 12),
    LITECOIN("LTC", "Litecoin", 8),
    ETHEREUM("ETH", "Ethereum", 18);

    companion object {
        fun fromSymbol(symbol: String): CryptoCurrency? {
            return entries.find { it.symbol.equals(symbol, ignoreCase = true) }
        }
    }
}

/**
 * Represents a cryptocurrency wallet address with its associated currency.
 */
data class WalletAddress(
    val address: String,
    val currency: CryptoCurrency,
    val label: String = ""
) {
    fun isValid(): Boolean {
        return address.isNotBlank() && when (currency) {
            CryptoCurrency.BITCOIN -> address.length in 26..62
            CryptoCurrency.MONERO -> address.length in 95..106
            CryptoCurrency.LITECOIN -> address.length in 26..34
            CryptoCurrency.ETHEREUM -> address.length == 42 && address.startsWith("0x")
        }
    }
}

/**
 * Represents the result of a fee calculation, splitting an amount
 * into the admin fee portion and the recipient portion.
 */
data class FeeBreakdown(
    val originalAmount: BigDecimal,
    val adminFeeAmount: BigDecimal,
    val recipientAmount: BigDecimal,
    val feePercentage: BigDecimal,
    val currency: CryptoCurrency
) {
    override fun toString(): String {
        return "FeeBreakdown(original=${originalAmount.toPlainString()} ${currency.symbol}, " +
                "fee=${adminFeeAmount.toPlainString()} ${currency.symbol} (${feePercentage.multiply(BigDecimal(100))}%), " +
                "recipient=${recipientAmount.toPlainString()} ${currency.symbol})"
    }
}

/**
 * Represents the type of transaction.
 */
enum class TransactionType {
    TRADE,
    DEPOSIT,
    WITHDRAWAL,
    FEE_TRANSFER
}

/**
 * Represents the status of a transaction.
 */
enum class TransactionStatus {
    PENDING,
    CONFIRMED,
    COMPLETED,
    FAILED,
    CANCELLED
}

/**
 * Represents a cryptocurrency transaction within the application.
 */
data class Transaction(
    val id: String,
    val type: TransactionType,
    val currency: CryptoCurrency,
    val amount: BigDecimal,
    val adminFeeAmount: BigDecimal,
    val recipientAmount: BigDecimal,
    val fromAddress: String,
    val toAddress: String,
    val adminWalletAddress: String,
    val status: TransactionStatus = TransactionStatus.PENDING,
    val txHash: String? = null,
    val feeTxHash: String? = null,
    val timestamp: Long = System.currentTimeMillis(),
    val description: String = ""
) {
    /**
     * Returns the fee percentage applied to this transaction.
     */
    fun feePercentage(): BigDecimal {
        return if (amount > BigDecimal.ZERO) {
            adminFeeAmount.divide(amount, 4, RoundingMode.HALF_UP)
        } else {
            BigDecimal.ZERO
        }
    }
}
