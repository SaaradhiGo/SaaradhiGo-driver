import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Cloud Messaging. Commented out until google-services.json is
    // added to android/app/ — enabling it without the file fails the build,
    // and push is a redundant dispatch path the app works without.
    // id("com.google.gms.google-services")
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
// `*.jks`/`*.keystore` are gitignored.
//
// WHY THIS FAILS LOUDLY
// ---------------------
// A release build with no signing material used to fall back to the DEBUG key
// silently. A debug-signed APK installs and runs, so the fallback is invisible
// until the Play Console rejects the upload -- or worse, until an "internal
// testing" build goes out signed with a key that is on every developer's
// machine and in every CI image.
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
        // Required by flutter_local_notifications for java.time on older APIs.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Distinct from the rider app (com.saaradhigo.rider) so the two get
        // separate Play listings, separate Firebase senders, and a driver's
        // FCM token can never deliver to the rider app.
        applicationId = "com.saaradhigo.driver"

        // google_maps_flutter and the background-location stack both need 21+;
        // flutter's floor is already above that.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Injected into AndroidManifest.xml's com.google.android.geo.API_KEY.
        // Pass at build time so the key is never committed:
        //   flutter build apk -Pmaps.apiKey=AIza...
        // An empty default keeps `flutter build apk --debug` working: the map
        // renders grey without a key, which is fine for a debug smoke build.
        manifestPlaceholders["MAPS_API_KEY"] =
            (project.findProperty("maps.apiKey") as String?) ?: ""
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
            // This was an unconditional `signingConfigs.getByName("debug")`
            // with a TODO: every release APK of the driver app was signed with
            // the debug key, which Play rejects and which is not a key anyone
            // owns. The guard above now stops a release build that has nothing
            // to sign with; the debug fallback is reachable only with
            // -PallowDebugSigning=true.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
