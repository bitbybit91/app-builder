package com.magoradesk.app.service

import com.magoradesk.app.model.CryptoCurrency
import com.magoradesk.app.model.TransactionType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Before
import org.junit.Test
import java.math.BigDecimal

/**
 * Unit tests for TransactionService.
 * Verifies that transactions correctly apply the 4% admin fee.
 */
class TransactionServiceTest {

    private lateinit var transactionService: TransactionService
    private lateinit var adminFeeService: AdminFeeService

    @Before
    fun setUp() {
        adminFeeService = AdminFeeService(
            adminWalletAddress = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa"
        )
        transactionService = TransactionService(adminFeeService)
    }

    @Test
    fun `createTradeTransaction applies 4 percent fee`() {
        val tx = transactionService.createTradeTransaction(
            amount = BigDecimal("5.00000000"),
            currency = CryptoCurrency.BITCOIN,
            fromAddress = "from_addr",
            toAddress = "to_addr"
        )

        assertEquals(TransactionType.TRADE, tx.type)
        assertEquals(BigDecimal("0.20000000"), tx.adminFeeAmount)
        assertEquals(BigDecimal("4.80000000"), tx.recipientAmount)
        assertEquals("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", tx.adminWalletAddress)
    }

    @Test
    fun `createDepositTransaction applies 4 percent fee`() {
        val tx = transactionService.createDepositTransaction(
            amount = BigDecimal("2.00000000"),
            currency = CryptoCurrency.BITCOIN,
            depositAddress = "deposit_addr"
        )

        assertEquals(TransactionType.DEPOSIT, tx.type)
        assertEquals(BigDecimal("0.08000000"), tx.adminFeeAmount)
        assertEquals(BigDecimal("1.92000000"), tx.recipientAmount)
    }

    @Test
    fun `createFeeTransferTransaction creates correct fee transfer`() {
        val tradeTx = transactionService.createTradeTransaction(
            amount = BigDecimal("10.00000000"),
            currency = CryptoCurrency.BITCOIN,
            fromAddress = "from_addr",
            toAddress = "to_addr"
        )

        val feeTx = transactionService.createFeeTransferTransaction(tradeTx)

        assertEquals(TransactionType.FEE_TRANSFER, feeTx.type)
        assertEquals(BigDecimal("0.40000000"), feeTx.amount)
        assertEquals("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", feeTx.toAddress)
        assertEquals(BigDecimal.ZERO, feeTx.adminFeeAmount)
    }

    @Test
    fun `trade transaction has correct description with fee info`() {
        val tx = transactionService.createTradeTransaction(
            amount = BigDecimal("1.00000000"),
            currency = CryptoCurrency.BITCOIN,
            fromAddress = "from_addr",
            toAddress = "to_addr"
        )

        assertNotNull(tx.description)
        assert(tx.description.contains("Fee:"))
        assert(tx.description.contains("0.04000000"))
    }
}
