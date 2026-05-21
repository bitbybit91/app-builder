package com.capitalmonero.app.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import android.os.Build

private val MoneroOrange = Color(0xFFFF6600)
private val MoneroGray = Color(0xFF4C4C4C)
private val White = Color(0xFFFFFFFF)

private val LightColorScheme = lightColorScheme(
    primary = MoneroOrange,
    onPrimary = White,
    secondary = MoneroGray,
    onSecondary = White,
    surface = Color(0xFFFAFAFA),
    onSurface = Color(0xFF1C1B1F),
)

private val DarkColorScheme = darkColorScheme(
    primary = MoneroOrange,
    onPrimary = Color(0xFF1C1B1F),
    secondary = Color(0xFFCCCCCC),
    onSecondary = Color(0xFF1C1B1F),
)

@Composable
fun CapitalMoneroTheme(
    darkTheme: Boolean = false,
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit,
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content,
    )
}
