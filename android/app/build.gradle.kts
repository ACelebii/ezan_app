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

val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

android {
    namespace = "com.acelebi.ezanvakti"
    ndkVersion = "28.2.13676358"
    compileSdk = 36  // <--- BURAYI TEKRAR 36 YAPIYORUZ

    defaultConfig {
        applicationId = "com.acelebi.ezanvakti"
        minSdk = 24      // async_wallpaper paketi minSdk 24 istiyor (Multimedya/Duvar Kağıdı özelliği)
        targetSdk = 36   // 22.09.2026: geolocator 14.0.2'ye güncellenmiş; Konum/Pusula/"Konumumu
                         // Kullan" üçü de telefonda çökmeden test edildi (eskiden 33'te tutuluyordu)
        versionCode = 1
        versionName = "1.0"
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }
    
    signingConfigs {
        getByName("debug") {
        }
        create("release") {
            // 22.09.2026: gerçek imza anahtarı (android/key.properties, git'e
            // eklenmez). Dosya yoksa (ör. CI/başka bilgisayar) derleme debug
            // anahtarına düşer, sessizce yanlış anahtarla imzalamaz.
            if (keystoreProperties.isEmpty) {
                initWith(getByName("debug"))
            } else {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
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
