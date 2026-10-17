import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// --- Firebase Cloud Messaging -----------------------------------------------
//
// Applied ONLY when android/app/google-services.json is present.
//
// That file is issued by the Firebase console for a specific Android client
// (package com.saaradhigo.driver) and it is not in this repository -- it is
// gitignored, because it belongs to a project the owner controls and has to
// be fetched per environment.
//
// The google-services plugin FAILS THE BUILD when the file is missing, with
// "File google-services.json is missing". Applying it unconditionally would
// mean this app could not be built, analysed or tested by anyone who has not
// been given the file -- including CI, which needs no push to run a test
// suite. Applying it conditionally means the build works everywhere, and
// becomes a real FCM build the moment the file is dropped in.
//
// The Dart side mirrors this exactly: PushService reports itself unavailable
// rather than throwing, and the app keeps dispatching over the WebSocket. See
// lib/core/notifications/push_service.dart.
val googleServicesFile = file("google-services.json")
if (googleServicesFile.exists()) {
    apply(plugin = "com.google.gms.google-services")
    logger.lifecycle("google-services.json found -- FCM is enabled for this build.")
} else {
    logger.lifecycle(
        "google-services.json absent -- building WITHOUT FCM. Push will report " +
            "itself unavailable at runtime and dispatch will rely on the WebSocket."
    )
}

// --- Release signing -------------------------------------------------------
//
// Material comes from one of two places, never from this file:
//
//   1. `android/key.properties` (a developer's machine), or
//   2. environment variables (CI):
//        ANDROID_KEYSTORE_BASE64  -> decoded to a keystore by the workflow
//        ANDROID_KEYSTORE_PATH    -> where the workflow wrote it
//        ANDROID_KEY_ALIAS
//        ANDROID_KEY_PASSWORD
//        ANDROID_STORE_PASSWORD
//
// No keystore and no password is ever committed. `key.properties` and
// `*.jks`/`*.keystore` are gitignored (android/.gitignore).
//
// WHY THIS FAILS LOUDLY
// ---------------------
// This file used to read:
//
//     release {
//         // TODO: Add your own signing config for the release build.
//         signingConfig = signingConfigs.getByName("debug")
//
// so every release APK was signed with the Android DEBUG key -- a key that
// ships with the SDK and is byte-identical on every developer machine and CI
// image. Play rejects it, and anything side-loaded from such a build is signed
// with a key nobody owns, so it can never be updated by a real build: a pilot
// driver would have to uninstall and lose local state to take an update.
//
// A debug-signed APK installs and runs, which is exactly why this survives
// review: `flutter test`, `flutter analyze` and a successful `flutter build
// apk --release` all pass with it.
//
// So: a release build with nothing to sign with now stops with an explanation.
// `-PallowDebugSigning=true` (or ALLOW_DEBUG_SIGNING=true) restores the old
// behaviour for `flutter run --release` on a dev machine, and says so in the
// build log every time.
//
// Debug builds are untouched -- CI builds a debug APK on every push and must
// keep working with no secrets at all.
fun signingEnv(name: String): String? =
    System.getenv(name)?.takeIf { it.isNotBlank() }

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(keystorePropertiesFile.inputStream())
    }
}

fun signingValue(propertyKey: String, envKey: String): String? =
    (keystoreProperties[propertyKey] as String?)?.takeIf { it.isNotBlank() }
        ?: signingEnv(envKey)

val releaseStoreFilePath = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")
val releaseKeyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
val releaseStorePassword = signingValue("storePassword", "ANDROID_STORE_PASSWORD")

val hasReleaseSigning = releaseStoreFilePath != null &&
    releaseKeyAlias != null &&
    releaseKeyPassword != null &&
    releaseStorePassword != null &&
    file(releaseStoreFilePath).exists()

val allowDebugSigning =
    (project.findProperty("allowDebugSigning") as String?)?.toBoolean() == true ||
        System.getenv("ALLOW_DEBUG_SIGNING")?.toBoolean() == true

// Only release tasks are gated. `assembleDebug`, `flutter test` and
// `flutter analyze` must never be blocked by a missing keystore.
val buildingRelease = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true) || it.contains("bundle", ignoreCase = true)
}

if (buildingRelease && !hasReleaseSigning && !allowDebugSigning) {
    throw GradleException(
        """
        Release build refused: no Android signing material.

        Supply either android/key.properties with storeFile/keyAlias/
        keyPassword/storePassword, or the environment variables
        ANDROID_KEYSTORE_PATH, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD and
        ANDROID_STORE_PASSWORD.

        To build a release APK signed with the DEBUG key on purpose -- never
        for distribution, because that key is not yours alone -- re-run with
        -PallowDebugSigning=true.
        """.trimIndent()
    )
}

if (buildingRelease && !hasReleaseSigning) {
    logger.warn(
        "WARNING: signing this RELEASE build with the DEBUG key " +
            "(allowDebugSigning). It cannot be distributed."
    )
}

android {
    namespace = "com.saaradhigo.driver"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications, which uses java.time on
        // API levels that do not have it. Without this the build fails at
        // :app:checkDebugAarMetadata with "requires core library desugaring
        // to be enabled" -- it is a hard requirement of the dependency, not
        // a preference.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Settled before the first upload, which is the only moment it is
        // free: an applicationId can never be changed afterwards.
        //
        // Was `com.saaradhigo.saaradhigo_driver`, which Flutter generated from
        // the project directory name -- it doubled the brand and carried an
        // underscore that would have appeared in the public Play URL. The
        // change cost nothing because nothing outside this repo was bound to
        // it: no Firebase client, no OAuth client, no deep link, no Play
        // listing, and no backend reference.
        //
        // `namespace` above moved with it, so the R/BuildConfig package and
        // the Kotlin source package agree; MainActivity.kt moved to match.
        applicationId = "com.saaradhigo.driver"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Declared only when every value resolved AND the keystore exists on disk.
    if (hasReleaseSigning) {
        signingConfigs {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storeFile = file(releaseStoreFilePath!!)
                storePassword = releaseStorePassword
            }
        }
    }

    buildTypes {
        release {
            // The guard above stops a release build that has nothing to sign
            // with; the debug fallback is reachable only with
            // -PallowDebugSigning=true, and logs a warning when it is used.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    // Same version the rider app ships, which is already running it.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
