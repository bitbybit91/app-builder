package com.magoradesk.app.ui.trade

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.Spinner
import android.widget.ArrayAdapter
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.magoradesk.app.MagoradeskApp
import com.magoradesk.app.R
import com.magoradesk.app.model.CryptoCurrency
import com.magoradesk.app.util.FormatUtils
import java.math.BigDecimal

/**
 * Fragment for creating new trade offers.
 * Displays the 4% admin fee that will be applied to the trade.
 */
class CreateTradeFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_create_trade, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val amountInput = view.findViewById<EditText>(R.id.edit_amount)
        val currencySpinner = view.findViewById<Spinner>(R.id.spinner_currency)
        val feePreview = view.findViewById<TextView>(R.id.text_fee_preview)
        val netAmountPreview = view.findViewById<TextView>(R.id.text_net_amount)
        val createButton = view.findViewById<Button>(R.id.button_create_trade)

        // Set up currency spinner
        val currencies = CryptoCurrency.entries.map { it.displayName }
        val adapter = ArrayAdapter(
            requireContext(),
            android.R.layout.simple_spinner_item,
            currencies
        )
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        currencySpinner.adapter = adapter

        createButton.setOnClickListener {
            val amountText = amountInput.text.toString()
            if (amountText.isBlank()) {
                Toast.makeText(requireContext(), R.string.enter_amount, Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val amount = BigDecimal(amountText)
            val currency = CryptoCurrency.entries[currencySpinner.selectedItemPosition]
            val feeService = MagoradeskApp.instance.getFeeService(currency)
            val breakdown = feeService.calculateFee(amount, currency)

            feePreview.text = getString(
                R.string.admin_fee_amount,
                FormatUtils.formatCryptoAmount(breakdown.adminFeeAmount, currency.symbol)
            )
            netAmountPreview.text = getString(
                R.string.net_amount,
                FormatUtils.formatCryptoAmount(breakdown.recipientAmount, currency.symbol)
            )

            Toast.makeText(
                requireContext(),
                getString(R.string.trade_created_with_fee, feeService.getFeePercentageDisplay()),
                Toast.LENGTH_LONG
            ).show()
        }
    }
}
