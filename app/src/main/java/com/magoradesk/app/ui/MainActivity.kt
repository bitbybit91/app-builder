package com.magoradesk.app.ui

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.navigation.NavController
import androidx.navigation.fragment.NavHostFragment
import androidx.navigation.ui.AppBarConfiguration
import androidx.navigation.ui.setupActionBarWithNavController
import androidx.navigation.ui.setupWithNavController
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.magoradesk.app.R

/**
 * Main Activity for Magoradesk P2P Cryptocurrency Trading App.
 *
 * Hosts the navigation graph with bottom navigation for:
 * - Trades: Browse and manage P2P trades
 * - Wallet: View balances and manage wallets
 * - Deposit: Deposit cryptocurrency
 * - Settings: App configuration and admin wallet settings
 */
class MainActivity : AppCompatActivity() {

    private lateinit var navController: NavController

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val navHostFragment = supportFragmentManager
            .findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        navController = navHostFragment.navController

        val bottomNav = findViewById<BottomNavigationView>(R.id.bottom_navigation)

        val appBarConfiguration = AppBarConfiguration(
            setOf(
                R.id.navigation_trades,
                R.id.navigation_wallet,
                R.id.navigation_deposit,
                R.id.navigation_settings
            )
        )

        setupActionBarWithNavController(navController, appBarConfiguration)
        bottomNav.setupWithNavController(navController)
    }

    override fun onSupportNavigateUp(): Boolean {
        return navController.navigateUp() || super.onSupportNavigateUp()
    }
}
