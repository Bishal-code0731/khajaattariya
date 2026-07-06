import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing reads from android/key.properties (git-ignored, never
// committed). Generate a keystore with:
//   keytool -genkey -v -keystore ~/khaja-attariya-release.jks -keyalg RSA \
//     -keysize 2048 -validity 10000 -alias khaja_attariya
// then create android/key.properties with:
//   storePassword=<your store password>
//   keyPassword=<your key password>
//   keyAlias=khaja_attariya
//   storeFile=/absolute/path/to/khaja-attariya-release.jks
// Until that file exists, release builds fall back to debug signing
// (fine for local testing, NOT for Play Store uploads).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.khajaattariya.khajaattariya"
    compileSdk = flutter.compileSdkVersion
    // Pinned above the Flutter default (26.x) because several plugins
    // (firebase_core, geolocator, flutter_image_compress, etc.) require
    // NDK 27+ — they're backward compatible, so this covers everyone.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.khajaattariya.khajaattariya"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
