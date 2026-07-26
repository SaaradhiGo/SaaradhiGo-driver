plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Cloud Messaging. Commented out until google-services.json is
    // added to android/app/ — enabling it without the file fails the build,
    // and push is a redundant dispatch path the app works without.
    // id("com.google.gms.google-services")
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

    buildTypes {
        release {
            // TODO: replace with the real upload key before the pilot.
            // Signing with the debug keys for now, so `flutter run --release`
            // works. A Play upload will be rejected until this is a real
            // keystore held outside the repo.
            signingConfig = signingConfigs.getByName("debug")
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
