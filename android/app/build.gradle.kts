plugins {
    id("com.android.application")
    id("kotlin-android")

    // The Flutter Gradle Plugin must be applied before Google services.
    id("dev.flutter.flutter-gradle-plugin")

    // ✅ Nécessaire pour Firebase (doit venir après Flutter)
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.wasfati_fb"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // ✅ Le même ID que dans Firebase Console
        applicationId = "com.example.wasfati_fb"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // 🔐 À remplacer par une vraie clé de signature plus tard
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Firebase BoM gère les versions automatiquement
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))

    // 🔥 Modules Firebase à activer selon ton usage :
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
}
