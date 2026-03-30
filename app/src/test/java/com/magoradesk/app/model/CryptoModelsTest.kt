package com.magoradesk.app.model

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal

/**
 * Unit tests for cryptocurrency model classes.
 */
class CryptoModelsTest {

    @Test
    fun `CryptoCurrency fromSymbol finds correct currency`() {
        assertEquals(CryptoCurrency.BITCOIN, CryptoCurrency.fromSymbol("BTC"))
        assertEquals(CryptoCurrency.MONERO, CryptoCurrency.fromSymbol("XMR"))
        assertEquals(CryptoCurrency.LITECOIN, CryptoCurrency.fromSymbol("LTC"))
        assertEquals(CryptoCurrency.ETHEREUM, CryptoCurrency.fromSymbol("ETH"))
    }

    @Test
    fun `CryptoCurrency fromSymbol is case insensitive`() {
        assertEquals(CryptoCurrency.BITCOIN, CryptoCurrency.fromSymbol("btc"))
        assertEquals(CryptoCurrency.MONERO, CryptoCurrency.fromSymbol("Xmr"))
    }

    @Test
    fun `CryptoCurrency fromSymbol returns null for unknown`() {
        assertNull(CryptoCurrency.fromSymbol("UNKNOWN"))
    }

    @Test
    fun `WalletAddress validation for Bitcoin`() {
        val valid = WalletAddress("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", CryptoCurrency.BITCOIN)
        assertTrue(valid.isValid())

        val invalid = WalletAddress("short", CryptoCurrency.BITCOIN)
        assertFalse(invalid.isValid())
    }

    @Test
    fun `WalletAddress validation for Ethereum`() {
        val valid = WalletAddress("0x742d35Cc6634C0532925a3b844Bc9e7595f2bD38", CryptoCurrency.ETHEREUM)
        assertTrue(valid.isValid())

        val invalidPrefix = WalletAddress("742d35Cc6634C0532925a3b844Bc9e7595f2bD38aa", CryptoCurrency.ETHEREUM)
        assertFalse(invalidPrefix.isValid())
    }

    @Test
    fun `FeeBreakdown toString contains all info`() {
        val breakdown = FeeBreakdown(
            originalAmount = BigDecimal("1.0"),
            adminFeeAmount = BigDecimal("0.04"),
            recipientAmount = BigDecimal("0.96"),
            feePercentage = BigDecimal("0.04"),
            currency = CryptoCurrency.BITCOIN
        )
        val str = breakdown.toString()
        assertTrue(str.contains("BTC"))
        assertTrue(str.contains("0.04"))
        assertTrue(str.contains("0.96"))
    }

    @Test
    fun `Transaction feePercentage calculation`() {
        val tx = Transaction(
            id = "test",
            type = TransactionType.TRADE,
            currency = CryptoCurrency.BITCOIN,
            amount = BigDecimal("10.0"),
            adminFeeAmount = BigDecimal("0.4"),
            recipientAmount = BigDecimal("9.6"),
            fromAddress = "from",
            toAddress = "to",
            adminWalletAddress = "admin"
        )
        assertEquals(BigDecimal("0.0400"), tx.feePercentage())
    }

    @Test
    fun `all CryptoCurrency entries have correct decimals`() {
        assertEquals(8, CryptoCurrency.BITCOIN.decimals)
        assertEquals(12, CryptoCurrency.MONERO.decimals)
        assertEquals(8, CryptoCurrency.LITECOIN.decimals)
        assertEquals(18, CryptoCurrency.ETHEREUM.decimals)
    }
}
