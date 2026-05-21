# CapitalMonero ProGuard rules

# Keep application class
-keep class com.capitalmonero.app.** { *; }

# Kotlin serialization
-keepattributes *Annotation*
-keepclassmembers class ** {
    @kotlinx.serialization.SerialName <fields>;
}

# Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# Compose
-keep class androidx.compose.** { *; }

# Generic rules
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
