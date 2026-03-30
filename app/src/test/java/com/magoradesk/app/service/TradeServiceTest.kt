package com.magoradesk.app.service

import com.magoradesk.app.model.CryptoCurrency
import com.magoradesk.app.model.TradeOffer
import com.magoradesk.app.model.TradeType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.math.BigDecimal

/**
 * Unit tests for TradeService.
 * Verifies that the 4% admin fee is correctly applied to trades.
 */
class TradeServiceTest {

    private lateinit var tradeService: TradeService
    private lateinit var adminFeeService: AdminFeeService

    @Before
    fun setUp() {
        adminFeeService = AdminFeeService(
            adminWalletAddress = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa"
        )
        tradeService = TradeService(adminFeeService)
    }

    private fun createTestOffer(
        amount: BigDecimal = BigDecimal("1.00000000"),
        currency: CryptoCurrency = CryptoCurrency.BITCOIN
    ): TradeOffer {
        return TradeOffer(
            id = "offer-1",
            type = TradeType.SELL,
            currency = currency,
            amount = amount,
            price = BigDecimal("50000.00"),
            fiatCurrency = "USD",
            minAmount = BigDecimal("0.001"),
            maxAmount = BigDecimal("10.0"),
            paymentMethod = "Bank Transfer",
            traderUsername = "seller1"
        )
    }

    @Test
    fun `createTrade applies 4 percent fee`() {
        val offer = createTestOffer()
        val trade = tradeService.createTrade(
            offer = offer,
            buyerUsername = "buyer1",
            cryptoAmount = BigDecimal("1.00000000"),
            fiatAmount = BigDecimal("50000.00")
        )

        assertEquals(BigDecimal("0.04000000"), trade.adminFeeAmount)
        assertEquals(BigDecimal("0.96000000"), trade.netCryptoAmount)
        assertEquals("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", trade.adminWalletAddress)
    }

    @Test
    fun `trade fee plus net equals total`() {
        val offer = createTestOffer()
        val trade = tradeService.createTrade(
            offer = offer,
            buyerUsername = "buyer1",
            cryptoAmount = BigDecimal("5.55555555"),
            fiatAmount = BigDecimal("277777.78")
        )

        val total = trade.adminFeeAmount.add(trade.netCryptoAmount)
        assertTrue(
            "Fee + net should approximately equal crypto amount",
            (trade.cryptoAmount.subtract(total)).abs() <= BigDecimal("0.00000001")
        )
    }

    @Test
    fun `processTradeRelease generates correct transfers`() {
        val offer = createTestOffer()
        val trade = tradeService.createTrade(
            offer = offer,
            buyerUsername = "buyer1",
            cryptoAmount = BigDecimal("2.00000000"),
            fiatAmount = BigDecimal("100000.00")
        )

        val result = tradeService.processTradeRelease(trade)

        assertNotNull(result)
        assertEquals(BigDecimal("0.08000000"), result.adminFeeTransfer.amount)
        assertEquals(BigDecimal("1.92000000"), result.buyerTransfer.amount)
        assertEquals(BigDecimal("2.00000000"), result.totalAmount)
        assertEquals("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", result.adminFeeTransfer.toAddress)
    }

    @Test
    fun `previewTradeFee shows correct breakdown`() {
        val breakdown = tradeService.previewTradeFee(
            BigDecimal("10.00000000"),
            CryptoCurrency.BITCOIN
        )

        assertEquals(BigDecimal("0.40000000"), breakdown.adminFeeAmount)
        assertEquals(BigDecimal("9.60000000"), breakdown.recipientAmount)
    }

    @Test
    fun `trade with Monero applies 4 percent fee`() {
        val offer = createTestOffer(currency = CryptoCurrency.MONERO)
        val trade = tradeService.createTrade(
            offer = offer,
            buyerUsername = "buyer1",
            cryptoAmount = BigDecimal("100.000000000000"),
            fiatAmount = BigDecimal("15000.00")
        )

        assertEquals(BigDecimal("4.000000000000"), trade.adminFeeAmount)
        assertEquals(BigDecimal("96.000000000000"), trade.netCryptoAmount)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `trade amount below minimum throws exception`() {
        val offer = createTestOffer()
        tradeService.createTrade(
            offer = offer,
            buyerUsername = "buyer1",
            cryptoAmount = BigDecimal("0.0001"),
            fiatAmount = BigDecimal("5.00")
        )
    }

    @Test(expected = IllegalArgumentException::class)
    fun `trade amount above maximum throws exception`() {
        val offer = createTestOffer()
        tradeService.createTrade(
            offer = offer,
            buyerUsername = "buyer1",
            cryptoAmount = BigDecimal("100.0"),
            fiatAmount = BigDecimal("5000000.00")
        )
    }
}
