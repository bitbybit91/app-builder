package com.magoradesk.app.util

import java.math.BigDecimal
import java.math.RoundingMode
import java.text.DecimalFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Utility functions for formatting cryptocurrency amounts, dates, and other values.
 */
object FormatUtils {

    private val cryptoFormat = DecimalFormat("#,##0.########")
    private val fiatFormat = DecimalFormat("#,##0.00")
    private val percentFormat = DecimalFormat("0.##%")
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)

    /**
     * Formats a cryptocurrency amount with appropriate decimal places.
     */
    fun formatCryptoAmount(amount: BigDecimal, symbol: String): String {
        return "${cryptoFormat.format(amount)} $symbol"
    }

    /**
     * Formats a fiat currency amount.
     */
    fun formatFiatAmount(amount: BigDecimal, currency: String): String {
        return "${fiatFormat.format(amount)} $currency"
    }

    /**
     * Formats a percentage value for display.
     */
    fun formatPercentage(percentage: BigDecimal): String {
        return "${percentage.multiply(BigDecimal(100)).setScale(2, RoundingMode.HALF_UP)}%"
    }

    /**
     * Formats a timestamp to a human-readable date string.
     */
    fun formatTimestamp(timestamp: Long): String {
        return dateFormat.format(Date(timestamp))
    }

    /**
     * Truncates a wallet address for display (shows first and last characters).
     */
    fun truncateAddress(address: String, prefixLength: Int = 8, suffixLength: Int = 6): String {
        if (address.length <= prefixLength + suffixLength + 3) return address
        return "${address.take(prefixLength)}...${address.takeLast(suffixLength)}"
    }
}
