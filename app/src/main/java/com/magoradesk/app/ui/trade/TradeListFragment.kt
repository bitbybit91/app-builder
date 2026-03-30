package com.magoradesk.app.ui.trade

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.magoradesk.app.MagoradeskApp
import com.magoradesk.app.R
import com.magoradesk.app.model.CryptoCurrency
import com.magoradesk.app.service.AdminFeeService
import com.magoradesk.app.util.FormatUtils
import java.math.BigDecimal

/**
 * Fragment displaying the list of available P2P trades.
 * Shows trade offers and active trades with the 4% admin fee clearly displayed.
 */
class TradeListFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_trade_list, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val feeInfoText = view.findViewById<TextView>(R.id.text_fee_info)
        feeInfoText.text = getString(
            R.string.trade_fee_notice,
            AdminFeeService.FEE_DISPLAY_PERCENTAGE
        )

        val recyclerView = view.findViewById<RecyclerView>(R.id.recycler_trades)
        recyclerView.layoutManager = LinearLayoutManager(requireContext())

        // Display fee preview
        val feePreviewText = view.findViewById<TextView>(R.id.text_fee_preview)
        val feeService = MagoradeskApp.instance.getFeeService(CryptoCurrency.BITCOIN)
        val sampleFee = feeService.calculateFee(BigDecimal("1.0"), CryptoCurrency.BITCOIN)
        feePreviewText.text = getString(
            R.string.fee_preview_example,
            FormatUtils.formatCryptoAmount(sampleFee.adminFeeAmount, "BTC"),
            FormatUtils.formatCryptoAmount(sampleFee.recipientAmount, "BTC")
        )
    }
}
