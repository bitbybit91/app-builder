package com.magoradesk.app.repository

import com.magoradesk.app.model.Deposit
import com.magoradesk.app.model.Trade
import com.magoradesk.app.model.TradeOffer
import com.magoradesk.app.model.Transaction

/**
 * Repository interface for managing trade-related data.
 * Implementations may use local database, remote API, or both.
 */
interface TradeRepository {

    /**
     * Gets all available trade offers.
     */
    suspend fun getOffers(): Result<List<TradeOffer>>

    /**
     * Gets a specific trade offer by ID.
     */
    suspend fun getOffer(offerId: String): Result<TradeOffer>

    /**
     * Creates a new trade offer.
     */
    suspend fun createOffer(offer: TradeOffer): Result<TradeOffer>

    /**
     * Gets all trades for the current user.
     */
    suspend fun getTrades(): Result<List<Trade>>

    /**
     * Gets a specific trade by ID.
     */
    suspend fun getTrade(tradeId: String): Result<Trade>

    /**
     * Updates a trade's status.
     */
    suspend fun updateTrade(trade: Trade): Result<Trade>

    /**
     * Gets all deposits for the current user.
     */
    suspend fun getDeposits(): Result<List<Deposit>>

    /**
     * Gets a specific deposit by ID.
     */
    suspend fun getDeposit(depositId: String): Result<Deposit>

    /**
     * Gets all transactions (trades, deposits, fee transfers).
     */
    suspend fun getTransactions(): Result<List<Transaction>>

    /**
     * Gets fee transfer transactions.
     */
    suspend fun getFeeTransactions(): Result<List<Transaction>>
}
