package com.magoradesk.app.ui.wallet

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import com.magoradesk.app.R
import com.magoradesk.app.service.AdminFeeService

/**
 * Fragment displaying the user's cryptocurrency wallet balances.
 * Shows available balances after the 4% admin fee deductions.
 */
class WalletFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_wallet, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val feeNotice = view.findViewById<TextView>(R.id.text_fee_notice)
        feeNotice.text = getString(
            R.string.wallet_fee_notice,
            AdminFeeService.FEE_DISPLAY_PERCENTAGE
        )
    }
}
