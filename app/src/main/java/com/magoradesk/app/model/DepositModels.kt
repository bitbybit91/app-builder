package com.magoradesk.app.model

import java.math.BigDecimal

/**
 * Represents a deposit into the application.
 */
data class Deposit(
    val id: String,
    val currency: CryptoCurrency,
    val amount: BigDecimal,
    val adminFeeAmount: BigDecimal,
    val netAmount: BigDecimal,
    val depositAddress: String,
    val adminWalletAddress: String,
    val txHash: String? = null,
    val feeTxHash: String? = null,
    val status: DepositStatus = DepositStatus.PENDING,
    val confirmations: Int = 0,
    val requiredConfirmations: Int = 1,
    val createdAt: Long = System.currentTimeMillis(),
    val confirmedAt: Long? = null
) {
    fun isConfirmed(): Boolean = confirmations >= requiredConfirmations
}

/**
 * Represents the status of a deposit.
 */
enum class DepositStatus {
    PENDING,
    CONFIRMING,
    CONFIRMED,
    FEE_SENT,
    COMPLETED,
    FAILED
}
