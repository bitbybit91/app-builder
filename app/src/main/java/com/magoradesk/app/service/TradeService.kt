package com.magoradesk.app.service

import com.magoradesk.app.model.*
import java.math.BigDecimal
import java.util.UUID

/**
 * Service responsible for processing cryptocurrency trades with the 4% admin fee.
 *
 * When a trade is executed:
 * 1. The seller's crypto is placed in escrow
 * 2. Once payment is confirmed, crypto is released
 * 3. 4% of the trade amount is sent to the admin wallet
 * 4. The remaining 96% is sent to the buyer
 */
class TradeService(
    private val adminFeeService: AdminFeeService
) {

    /**
     * Creates a new trade from a trade offer, calculating the 4% admin fee.
     *
     * @param offer The trade offer being accepted
     * @param buyerUsername The username of the buyer
     * @param cryptoAmount The amount of crypto being traded
     * @param fiatAmount The fiat amount for the trade
     * @return The created Trade with fee calculations applied
     */
    fun createTrade(
        offer: TradeOffer,
        buyerUsername: String,
        cryptoAmount: BigDecimal,
        fiatAmount: BigDecimal
    ): Trade {
        require(cryptoAmount > BigDecimal.ZERO) { "Trade amount must be positive" }
        require(cryptoAmount >= offer.minAmount) { "Amount below minimum" }
        require(cryptoAmount <= offer.maxAmount) { "Amount above maximum" }

        val feeBreakdown = adminFeeService.calculateFee(cryptoAmount, offer.currency)

        return Trade(
            id = UUID.randomUUID().toString(),
            offerId = offer.id,
            buyerUsername = buyerUsername,
            sellerUsername = offer.traderUsername,
            currency = offer.currency,
            cryptoAmount = cryptoAmount,
            fiatAmount = fiatAmount,
            fiatCurrency = offer.fiatCurrency,
            adminFeeAmount = feeBreakdown.adminFeeAmount,
            netCryptoAmount = feeBreakdown.recipientAmount,
            paymentMethod = offer.paymentMethod,
            adminWalletAddress = adminFeeService.getAdminWalletAddress()
        )
    }

    /**
     * Processes the release of crypto for a completed trade.
     * Splits the amount: 4% to admin wallet, 96% to buyer.
     *
     * @param trade The trade to process
     * @return TransferResult containing both transfer details
     */
    fun processTradeRelease(trade: Trade): TradeTransferResult {
        val feeTransfer = CryptoTransfer(
            amount = trade.adminFeeAmount,
            currency = trade.currency,
            toAddress = trade.adminWalletAddress,
            purpose = "Admin fee (${adminFeeService.getFeePercentageDisplay()}) for trade ${trade.id}"
        )

        val buyerTransfer = CryptoTransfer(
            amount = trade.netCryptoAmount,
            currency = trade.currency,
            toAddress = "", // Set by buyer's wallet address
            purpose = "Trade ${trade.id} crypto release to buyer"
        )

        return TradeTransferResult(
            tradeId = trade.id,
            adminFeeTransfer = feeTransfer,
            buyerTransfer = buyerTransfer,
            totalAmount = trade.cryptoAmount,
            feePercentage = adminFeeService.getFeePercentage()
        )
    }

    /**
     * Calculates the fee preview for display before confirming a trade.
     *
     * @param amount The trade amount
     * @param currency The cryptocurrency
     * @return FeeBreakdown with the fee details
     */
    fun previewTradeFee(amount: BigDecimal, currency: CryptoCurrency): FeeBreakdown {
        return adminFeeService.calculateFee(amount, currency)
    }
}

/**
 * Represents a cryptocurrency transfer to be executed.
 */
data class CryptoTransfer(
    val amount: BigDecimal,
    val currency: CryptoCurrency,
    val toAddress: String,
    val purpose: String
)

/**
 * Result of processing a trade release, containing both the admin fee
 * transfer and the buyer transfer details.
 */
data class TradeTransferResult(
    val tradeId: String,
    val adminFeeTransfer: CryptoTransfer,
    val buyerTransfer: CryptoTransfer,
    val totalAmount: BigDecimal,
    val feePercentage: BigDecimal
)
