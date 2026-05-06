# Default ProGuard rules for Flutter/Android release build.
# Flutter-specific rules are already provided by the Flutter Gradle plugin.

# Keep Flutter wrapper classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Kotlin metadata
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# Keep application entry point
-keep class com.magoradesk.app.** { *; }

# Suppress warnings for optional dependencies
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**

# Retrofit
-keepattributes Exceptions
-keepclasseswithmembers class * {
    @retrofit2.http.* <methods>;
}

# OkHttp & Okio
-dontwarn okhttp3.**
-dontwarn okio.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Gson / JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
