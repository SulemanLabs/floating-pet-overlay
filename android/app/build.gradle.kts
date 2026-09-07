import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Must be applied last so it can see the other Android plugins' config.
    id("com.google.gms.google-services")
    // Uploads mapping/symbol info at build time so Crashlytics can
    // de-obfuscate release stack traces.
    id("com.google.firebase.crashlytics")
}

// Release signing: reads android/key.properties if present (see section 33 /
// README "Release Readiness" for how to generate a keystore and populate
// this file). Falls back to debug signing so `flutter build apk --release`
// keeps working out of the box on machines without a release keystore.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.sulemanlabs.floatingstreak"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.sulemanlabs.floatingstreak"
        // TYPE_APPLICATION_OVERLAY and notification channels both require API 26+;
        // pinning the floor here (rather than trusting Flutter's default, which can
        // be lower) keeps the overlay feature set from silently degrading.
        minSdk = maxOf(flutter.minSdkVersion, 26)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
            signingConfig = if (hasReleaseKeystore) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // NotificationCompat (OverlayNotificationFactory) and ContextCompat
    // (MainActivity's foreground-service start) — declared explicitly rather
    // than relying on whatever the Flutter embedding happens to pull in
    // transitively.
    implementation("androidx.core:core-ktx:1.15.0")

    // Renders imported Lottie JSON pets inside the overlay window (PetRenderer).
    implementation("com.airbnb.android:lottie:6.6.0")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
