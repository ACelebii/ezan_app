import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { load(it) }
    }
}
val mapsApiKey: String = localProperties.getProperty("MAPS_API_KEY", "")

android {
    namespace = "com.example.ezan_app"
    ndkVersion = "28.2.13676358"
    compileSdk = 36  // <--- BURAYI TEKRAR 36 YAPIYORUZ

    defaultConfig {
        applicationId = "com.example.ezan_app"
        minSdk = flutter.minSdkVersion      // Burası 23 kalıyor (Firebase'in çalışması için şart)
        targetSdk = 33   // Burası 33 kalıyor (Konum/Pusula servisinin çökmemsi için)
        versionCode = 1
        versionName = "1.0"
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }
    
    signingConfigs {
        getByName("debug") {
        }
        create("release") {
            // Debug sertifikasını release için kopyalıyoruz
            initWith(getByName("debug"))
        }
    }

    buildTypes {
        getByName("release") {
            // İmza ayarını buraya bağladık
            signingConfig = signingConfigs.getByName("release")
            
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }
} // <--- ANDROID bloğunun bittiği yer burası olmalı!

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
