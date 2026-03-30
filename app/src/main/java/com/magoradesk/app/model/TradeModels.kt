package com.magoradesk.app.model

import java.math.BigDecimal

/**
 * Represents a trade offer (buy or sell) on the P2P marketplace.
 */
data class TradeOffer(
    val id: String,
    val type: TradeType,
    val currency: CryptoCurrency,
    val amount: BigDecimal,
    val price: BigDecimal,
    val fiatCurrency: String,
    val minAmount: BigDecimal,
    val maxAmount: BigDecimal,
    val paymentMethod: String,
    val traderUsername: String,
    val description: String = "",
    val isActive: Boolean = true,
    val createdAt: Long = System.currentTimeMillis()
)

/**
 * Represents the type of trade.
 */
enum class TradeType {
    BUY,
    SELL
}

/**
 * Represents an active trade between two users.
 */
data class Trade(
    val id: String,
    val offerId: String,
    val buyerUsername: String,
    val sellerUsername: String,
    val currency: CryptoCurrency,
    val cryptoAmount: BigDecimal,
    val fiatAmount: BigDecimal,
    val fiatCurrency: String,
    val adminFeeAmount: BigDecimal,
    val netCryptoAmount: BigDecimal,
    val paymentMethod: String,
    val status: TradeStatus = TradeStatus.CREATED,
    val escrowAddress: String = "",
    val adminWalletAddress: String = "",
    val createdAt: Long = System.currentTimeMillis(),
    val completedAt: Long? = null
)

/**
 * Represents the status of a trade.
 */
enum class TradeStatus {
    CREATED,
    ESCROW_FUNDED,
    PAYMENT_SENT,
    PAYMENT_CONFIRMED,
    CRYPTO_RELEASED,
    COMPLETED,
    DISPUTED,
    CANCELLED
}
