plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.cashsify.android"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.cashsify.android"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 28
        targetSdk = 35
        versionCode = 12
        versionName = "2.0"
    }

    signingConfigs {
        create("release") {
            storeFile = file("playstore-key.jks")
            storePassword = "Admin1234567890"
            keyAlias = "cashsifyupload"
            keyPassword = "Admin1234567890"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true // Enables code shrinking, obfuscation, and optimization
            //proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Unity Ads mediation
    implementation("com.google.ads.mediation:unity:4.12.2.0")
    
    // Additional mediation networks for higher fill rates
    implementation("com.google.ads.mediation:facebook:6.17.0.0")
    implementation("com.google.ads.mediation:applovin:12.6.0.0")
    implementation("com.google.ads.mediation:ironsource:8.3.0.0")
}
