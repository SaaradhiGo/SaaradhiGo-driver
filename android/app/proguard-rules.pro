# R8 rules for the release build.
#
# Flutter's own rules cover the engine; these cover the plugins that use
# reflection or are referenced only from native code, which R8 would
# otherwise strip and turn into a runtime crash that debug builds never show.

# Firebase Cloud Messaging
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Services (maps + location)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# flutter_local_notifications keeps notification payload models via Gson.
-keep class com.dexterous.** { *; }

# flutter_background_service starts its service from the manifest.
-keep class id.flutter.flutter_background_service.** { *; }
