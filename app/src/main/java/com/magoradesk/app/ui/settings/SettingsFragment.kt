package com.magoradesk.app.ui.settings

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.magoradesk.app.R
import com.magoradesk.app.model.CryptoCurrency
import com.magoradesk.app.service.AdminFeeService
import com.magoradesk.app.service.AdminWalletConfig

/**
 * Fragment for app settings, including admin wallet configuration.
 * Displays the current admin fee percentage and wallet addresses.
 */
class SettingsFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_settings, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val feeInfo = view.findViewById<TextView>(R.id.text_fee_info)
        feeInfo.text = getString(
            R.string.settings_fee_info,
            AdminFeeService.FEE_DISPLAY_PERCENTAGE
        )

        val btcWalletInput = view.findViewById<EditText>(R.id.edit_btc_wallet)
        val xmrWalletInput = view.findViewById<EditText>(R.id.edit_xmr_wallet)
        val ltcWalletInput = view.findViewById<EditText>(R.id.edit_ltc_wallet)
        val ethWalletInput = view.findViewById<EditText>(R.id.edit_eth_wallet)

        // Load current admin wallet addresses
        btcWalletInput.setText(AdminWalletConfig.getAdminWalletAddress(CryptoCurrency.BITCOIN))
        xmrWalletInput.setText(AdminWalletConfig.getAdminWalletAddress(CryptoCurrency.MONERO))
        ltcWalletInput.setText(AdminWalletConfig.getAdminWalletAddress(CryptoCurrency.LITECOIN))
        ethWalletInput.setText(AdminWalletConfig.getAdminWalletAddress(CryptoCurrency.ETHEREUM))

        val saveButton = view.findViewById<Button>(R.id.button_save_wallets)
        saveButton.setOnClickListener {
            saveWalletAddresses(
                btcWalletInput.text.toString(),
                xmrWalletInput.text.toString(),
                ltcWalletInput.text.toString(),
                ethWalletInput.text.toString()
            )
        }

        // Show unconfigured wallet warnings
        val warningText = view.findViewById<TextView>(R.id.text_wallet_warning)
        val unconfigured = AdminWalletConfig.getUnconfiguredWallets()
        if (unconfigured.isNotEmpty()) {
            warningText.visibility = View.VISIBLE
            warningText.text = getString(
                R.string.unconfigured_wallets_warning,
                unconfigured.joinToString(", ") { it.symbol }
            )
        } else {
            warningText.visibility = View.GONE
        }
    }

    private fun saveWalletAddresses(btc: String, xmr: String, ltc: String, eth: String) {
        if (btc.isNotBlank()) AdminWalletConfig.setAdminWalletAddress(CryptoCurrency.BITCOIN, btc)
        if (xmr.isNotBlank()) AdminWalletConfig.setAdminWalletAddress(CryptoCurrency.MONERO, xmr)
        if (ltc.isNotBlank()) AdminWalletConfig.setAdminWalletAddress(CryptoCurrency.LITECOIN, ltc)
        if (eth.isNotBlank()) AdminWalletConfig.setAdminWalletAddress(CryptoCurrency.ETHEREUM, eth)

        Toast.makeText(
            requireContext(),
            R.string.wallets_saved,
            Toast.LENGTH_SHORT
        ).show()
    }
}
