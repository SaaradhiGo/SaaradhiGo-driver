# Flutter Wrapper Keep Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# SaaradhiGo Driver Application & Models
-keep class com.saaradhigo.saaradhigo_driver.** { *; }
-keepclassmembers enum * { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Geolocator Service
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.geolocator.GeolocatorLocationService { *; }

# Flutter Secure Storage & Crypto
-keep class androidx.security.crypto.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# OkHttp & WebSocket
-dontwarn okhttp3.**
-dontwarn okio.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
