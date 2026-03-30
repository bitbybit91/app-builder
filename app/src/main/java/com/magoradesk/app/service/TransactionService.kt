package com.magoradesk.app.service

import com.magoradesk.app.model.CryptoCurrency
import com.magoradesk.app.model.Transaction
import com.magoradesk.app.model.TransactionStatus
import com.magoradesk.app.model.TransactionType
import java.math.BigDecimal
import java.util.UUID

/**
 * Service responsible for creating and managing cryptocurrency transactions,
 * including the automatic 4% admin fee distribution.
 *
 * Every transaction processed through this service automatically calculates
 * and includes the admin fee transfer to the configured admin wallet.
 */
class TransactionService(
    private val adminFeeService: AdminFeeService
) {

    /**
     * Creates a trade transaction with the 4% admin fee applied.
     *
     * @param amount The total trade amount
     * @param currency The cryptocurrency
     * @param fromAddress The sender's wallet address
     * @param toAddress The recipient's wallet address
     * @return Transaction with fee calculations
     */
    fun createTradeTransaction(
        amount: BigDecimal,
        currency: CryptoCurrency,
        fromAddress: String,
        toAddress: String
    ): Transaction {
        val feeBreakdown = adminFeeService.calculateFee(amount, currency)

        return Transaction(
            id = UUID.randomUUID().toString(),
            type = TransactionType.TRADE,
            currency = currency,
            amount = amount,
            adminFeeAmount = feeBreakdown.adminFeeAmount,
            recipientAmount = feeBreakdown.recipientAmount,
            fromAddress = fromAddress,
            toAddress = toAddress,
            adminWalletAddress = adminFeeService.getAdminWalletAddress(),
            description = "Trade: ${amount.toPlainString()} ${currency.symbol} " +
                    "(Fee: ${feeBreakdown.adminFeeAmount.toPlainString()} ${currency.symbol})"
        )
    }

    /**
     * Creates a deposit transaction with the 4% admin fee applied.
     *
     * @param amount The total deposit amount
     * @param currency The cryptocurrency
     * @param depositAddress The deposit receiving address
     * @return Transaction with fee calculations
     */
    fun createDepositTransaction(
        amount: BigDecimal,
        currency: CryptoCurrency,
        depositAddress: String
    ): Transaction {
        val feeBreakdown = adminFeeService.calculateFee(amount, currency)

        return Transaction(
            id = UUID.randomUUID().toString(),
            type = TransactionType.DEPOSIT,
            currency = currency,
            amount = amount,
            adminFeeAmount = feeBreakdown.adminFeeAmount,
            recipientAmount = feeBreakdown.recipientAmount,
            fromAddress = depositAddress,
            toAddress = depositAddress,
            adminWalletAddress = adminFeeService.getAdminWalletAddress(),
            description = "Deposit: ${amount.toPlainString()} ${currency.symbol} " +
                    "(Fee: ${feeBreakdown.adminFeeAmount.toPlainString()} ${currency.symbol})"
        )
    }

    /**
     * Creates the admin fee transfer transaction that accompanies every
     * trade or deposit.
     *
     * @param parentTransaction The original trade/deposit transaction
     * @return Transaction representing the fee transfer to admin wallet
     */
    fun createFeeTransferTransaction(parentTransaction: Transaction): Transaction {
        return Transaction(
            id = UUID.randomUUID().toString(),
            type = TransactionType.FEE_TRANSFER,
            currency = parentTransaction.currency,
            amount = parentTransaction.adminFeeAmount,
            adminFeeAmount = BigDecimal.ZERO,
            recipientAmount = parentTransaction.adminFeeAmount,
            fromAddress = parentTransaction.fromAddress,
            toAddress = adminFeeService.getAdminWalletAddress(),
            adminWalletAddress = adminFeeService.getAdminWalletAddress(),
            description = "Admin fee transfer for transaction ${parentTransaction.id}"
        )
    }
}
