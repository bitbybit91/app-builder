# CapitalMonero — release ProGuard / R8 rules.
# Kept conservative because we want builds to finish on 4 GB RAM hosts
# without R8 having to perform heavy whole-program analysis.

-dontwarn io.flutter.embedding.**
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Drift / SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Firebase (production / staging flavors only).
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Mobile scanner native bindings.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Local auth (biometrics).
-keep class androidx.biometric.** { *; }

# PointyCastle / BouncyCastle reflective use.
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Annotations.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# JSON model classes.
-keep class com.capitalmonero.app.** { *; }

# Misc.
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
