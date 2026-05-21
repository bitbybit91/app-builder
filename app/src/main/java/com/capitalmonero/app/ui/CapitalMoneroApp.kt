package com.capitalmonero.app.ui

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.capitalmonero.app.ui.home.HomeScreen
import com.capitalmonero.app.ui.about.AboutScreen

sealed class Screen(val route: String) {
    data object Home : Screen("home")
    data object About : Screen("about")
}

@Composable
fun CapitalMoneroApp() {
    val navController = rememberNavController()
    NavHost(navController = navController, startDestination = Screen.Home.route) {
        composable(Screen.Home.route) {
            HomeScreen(onNavigateToAbout = { navController.navigate(Screen.About.route) })
        }
        composable(Screen.About.route) {
            AboutScreen(onBack = { navController.popBackStack() })
        }
    }
}
