import java.util.Properties
import java.io.FileInputStream

// Load signing properties
val keystoreProperties = Properties().apply {
    load(rootProject.file("key.properties").inputStream())
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // ✅ CHANGE THIS LINE
    namespace   = "com.nydatai.kilimoafya"
    compileSdk  = flutter.compileSdkVersion
    ndkVersion  = "27.0.12077973"

    defaultConfig {
        // ✅ AND CHANGE THIS LINE
        applicationId = "com.nydatai.kilimoafya"
        minSdk        = flutter.minSdkVersion
        targetSdk     = flutter.targetSdkVersion
        versionCode   = flutter.versionCode
        versionName   = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile     = rootProject.file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias      = keystoreProperties["keyAlias"] as String
            keyPassword   = keystoreProperties["keyPassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled   = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig     = signingConfigs.getByName("release")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }
}

flutter {
    source = "../.."
}



