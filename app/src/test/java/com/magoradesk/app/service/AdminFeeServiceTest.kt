package com.magoradesk.app.service

import com.magoradesk.app.model.CryptoCurrency
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.math.BigDecimal
import java.math.RoundingMode

/**
 * Unit tests for AdminFeeService.
 * Verifies that the 4% admin fee is correctly calculated for all
 * supported cryptocurrencies across various amounts.
 */
class AdminFeeServiceTest {

    private lateinit var feeService: AdminFeeService

    @Before
    fun setUp() {
        feeService = AdminFeeService(
            adminWalletAddress = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa"
        )
    }

    @Test
    fun `default fee percentage is 4 percent`() {
        assertEquals(BigDecimal("0.04"), AdminFeeService.DEFAULT_FEE_PERCENTAGE)
    }

    @Test
    fun `calculate fee for 1 BTC trade`() {
        val amount = BigDecimal("1.00000000")
        val breakdown = feeService.calculateFee(amount, CryptoCurrency.BITCOIN)

        assertEquals(BigDecimal("0.04000000"), breakdown.adminFeeAmount)
        assertEquals(BigDecimal("0.96000000"), breakdown.recipientAmount)
        assertEquals(amount, breakdown.originalAmount)
    }

    @Test
    fun `calculate fee for 10 BTC trade`() {
        val amount = BigDecimal("10.00000000")
        val breakdown = feeService.calculateFee(amount, CryptoCurrency.BITCOIN)

        assertEquals(BigDecimal("0.40000000"), breakdown.adminFeeAmount)
        assertEquals(BigDecimal("9.60000000"), breakdown.recipientAmount)
    }

    @Test
    fun `calculate fee for 0_5 XMR deposit`() {
        val amount = BigDecimal("0.500000000000")
        val breakdown = feeService.calculateFee(amount, CryptoCurrency.MONERO)

        assertEquals(
            BigDecimal("0.020000000000"),
            breakdown.adminFeeAmount
        )
        assertEquals(
            BigDecimal("0.480000000000"),
            breakdown.recipientAmount
        )
    }

    @Test
    fun `calculate fee for 100 ETH trade`() {
        val amount = BigDecimal("100.000000000000000000")
        val breakdown = feeService.calculateFee(amount, CryptoCurrency.ETHEREUM)

        assertEquals(
            BigDecimal("4.000000000000000000"),
            breakdown.adminFeeAmount
        )
        assertEquals(
            BigDecimal("96.000000000000000000"),
            breakdown.recipientAmount
        )
    }

    @Test
    fun `calculate fee for small LTC amount`() {
        val amount = BigDecimal("0.01000000")
        val breakdown = feeService.calculateFee(amount, CryptoCurrency.LITECOIN)

        assertEquals(BigDecimal("0.00040000"), breakdown.adminFeeAmount)
        assertEquals(BigDecimal("0.00960000"), breakdown.recipientAmount)
    }

    @Test
    fun `fee plus recipient equals original amount`() {
        val amount = BigDecimal("7.77777777")
        val breakdown = feeService.calculateFee(amount, CryptoCurrency.BITCOIN)

        val total = breakdown.adminFeeAmount.add(breakdown.recipientAmount)
        // Allow for rounding tolerance
        assertTrue(
            "Fee + recipient should approximately equal original",
            (amount.subtract(total)).abs() <= BigDecimal("0.00000001")
        )
    }

    @Test
    fun `zero amount returns zero fee`() {
        val breakdown = feeService.calculateFee(BigDecimal.ZERO, CryptoCurrency.BITCOIN)

        assertEquals(BigDecimal.ZERO, breakdown.adminFeeAmount)
        assertEquals(BigDecimal.ZERO, breakdown.recipientAmount)
    }

    @Test
    fun `very small amount below threshold returns no fee`() {
        val amount = BigDecimal("0.000000001")
        val breakdown = feeService.calculateFee(amount, CryptoCurrency.BITCOIN)

        // Below minimum amount for fee
        assertEquals(BigDecimal.ZERO, breakdown.adminFeeAmount)
    }

    @Test
    fun `calculateTradeFee returns correct fee`() {
        val amount = BigDecimal("5.00000000")
        val fee = feeService.calculateTradeFee(amount, CryptoCurrency.BITCOIN)

        assertEquals(BigDecimal("0.20000000"), fee)
    }

    @Test
    fun `calculateDepositFee returns correct fee`() {
        val amount = BigDecimal("2.50000000")
        val fee = feeService.calculateDepositFee(amount, CryptoCurrency.BITCOIN)

        assertEquals(BigDecimal("0.10000000"), fee)
    }

    @Test
    fun `getNetAmount returns correct recipient amount`() {
        val amount = BigDecimal("10.00000000")
        val net = feeService.getNetAmount(amount, CryptoCurrency.BITCOIN)

        assertEquals(BigDecimal("9.60000000"), net)
    }

    @Test
    fun `fee percentage display is 4 percent`() {
        assertEquals("4%", feeService.getFeePercentageDisplay())
    }

    @Test
    fun `admin wallet address is returned correctly`() {
        assertEquals("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", feeService.getAdminWalletAddress())
    }

    @Test(expected = IllegalArgumentException::class)
    fun `negative amount throws exception`() {
        feeService.calculateFee(BigDecimal("-1.0"), CryptoCurrency.BITCOIN)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `blank wallet address throws exception`() {
        AdminFeeService(adminWalletAddress = "")
    }

    @Test(expected = IllegalArgumentException::class)
    fun `fee percentage above max throws exception`() {
        AdminFeeService(
            adminWalletAddress = "test_address",
            feePercentage = BigDecimal("0.11")
        )
    }

    @Test
    fun `custom fee percentage works correctly`() {
        val customService = AdminFeeService(
            adminWalletAddress = "test_address",
            feePercentage = BigDecimal("0.05")
        )
        val breakdown = customService.calculateFee(
            BigDecimal("10.00000000"),
            CryptoCurrency.BITCOIN
        )

        assertEquals(BigDecimal("0.50000000"), breakdown.adminFeeAmount)
        assertEquals(BigDecimal("9.50000000"), breakdown.recipientAmount)
    }

    @Test
    fun `fee is calculated for all supported currencies`() {
        val amount = BigDecimal("1")
        CryptoCurrency.entries.forEach { currency ->
            val breakdown = feeService.calculateFee(amount, currency)
            assertNotNull("Fee breakdown should not be null for ${currency.symbol}", breakdown)
            assertTrue(
                "Admin fee should be positive for ${currency.symbol}",
                breakdown.adminFeeAmount > BigDecimal.ZERO
            )
        }
    }
}
