plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.registro_paquetes"

    compileSdk = 36   // 🔴 CLAVE
    buildToolsVersion = "36.0.0" 

    defaultConfig {
        applicationId = "com.example.registro_paquetes"
        minSdk = flutter.minSdkVersion
        targetSdk = 34   // puede quedarse en 34
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}



flutter {
    source = "../.."
}
