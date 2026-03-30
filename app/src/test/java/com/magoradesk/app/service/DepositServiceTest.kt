package com.magoradesk.app.service

import com.magoradesk.app.model.CryptoCurrency
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.math.BigDecimal

/**
 * Unit tests for DepositService.
 * Verifies that the 4% admin fee is correctly applied to deposits.
 */
class DepositServiceTest {

    private lateinit var depositService: DepositService
    private lateinit var adminFeeService: AdminFeeService

    @Before
    fun setUp() {
        adminFeeService = AdminFeeService(
            adminWalletAddress = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa"
        )
        depositService = DepositService(adminFeeService)
    }

    @Test
    fun `processDeposit applies 4 percent fee`() {
        val deposit = depositService.processDeposit(
            amount = BigDecimal("1.00000000"),
            currency = CryptoCurrency.BITCOIN,
            depositAddress = "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
        )

        assertEquals(BigDecimal("0.04000000"), deposit.adminFeeAmount)
        assertEquals(BigDecimal("0.96000000"), deposit.netAmount)
        assertEquals("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", deposit.adminWalletAddress)
    }

    @Test
    fun `deposit fee plus net equals total`() {
        val deposit = depositService.processDeposit(
            amount = BigDecimal("3.33333333"),
            currency = CryptoCurrency.BITCOIN,
            depositAddress = "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
        )

        val total = deposit.adminFeeAmount.add(deposit.netAmount)
        assertTrue(
            "Fee + net should approximately equal deposit amount",
            (deposit.amount.subtract(total)).abs() <= BigDecimal("0.00000001")
        )
    }

    @Test
    fun `deposit with Monero applies 4 percent fee`() {
        val deposit = depositService.processDeposit(
            amount = BigDecimal("50.000000000000"),
            currency = CryptoCurrency.MONERO,
            depositAddress = "4" + "A".repeat(94)
        )

        assertEquals(BigDecimal("2.000000000000"), deposit.adminFeeAmount)
        assertEquals(BigDecimal("48.000000000000"), deposit.netAmount)
    }

    @Test
    fun `deposit with Ethereum applies 4 percent fee`() {
        val deposit = depositService.processDeposit(
            amount = BigDecimal("25.000000000000000000"),
            currency = CryptoCurrency.ETHEREUM,
            depositAddress = "0x742d35Cc6634C0532925a3b844Bc9e7595f2bD38"
        )

        assertEquals(BigDecimal("1.000000000000000000"), deposit.adminFeeAmount)
        assertEquals(BigDecimal("24.000000000000000000"), deposit.netAmount)
    }

    @Test
    fun `previewDepositFee shows correct breakdown`() {
        val breakdown = depositService.previewDepositFee(
            BigDecimal("10.00000000"),
            CryptoCurrency.BITCOIN
        )

        assertEquals(BigDecimal("0.40000000"), breakdown.adminFeeAmount)
        assertEquals(BigDecimal("9.60000000"), breakdown.recipientAmount)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `zero deposit amount throws exception`() {
        depositService.processDeposit(
            amount = BigDecimal.ZERO,
            currency = CryptoCurrency.BITCOIN,
            depositAddress = "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
        )
    }

    @Test(expected = IllegalArgumentException::class)
    fun `blank deposit address throws exception`() {
        depositService.processDeposit(
            amount = BigDecimal("1.0"),
            currency = CryptoCurrency.BITCOIN,
            depositAddress = ""
        )
    }

    @Test
    fun `deposit has correct required confirmations`() {
        val btcDeposit = depositService.processDeposit(
            BigDecimal("1.0"), CryptoCurrency.BITCOIN, "addr1"
        )
        assertEquals(3, btcDeposit.requiredConfirmations)

        val xmrDeposit = depositService.processDeposit(
            BigDecimal("1.0"), CryptoCurrency.MONERO, "addr2"
        )
        assertEquals(10, xmrDeposit.requiredConfirmations)

        val ltcDeposit = depositService.processDeposit(
            BigDecimal("1.0"), CryptoCurrency.LITECOIN, "addr3"
        )
        assertEquals(6, ltcDeposit.requiredConfirmations)

        val ethDeposit = depositService.processDeposit(
            BigDecimal("1.0"), CryptoCurrency.ETHEREUM, "addr4"
        )
        assertEquals(12, ethDeposit.requiredConfirmations)
    }
}
