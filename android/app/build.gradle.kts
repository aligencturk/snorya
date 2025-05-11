import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// 🔐 Keystore'u oku (kesin yolu kullan)
val keystoreProperties = Properties()
val keystorePath = file("../key.properties")
if (keystorePath.exists()) {
    println("✅ key.properties bulundu.")
    keystoreProperties.load(FileInputStream(keystorePath))
    println("🧪 storeFile: " + keystoreProperties["storeFile"])
} else {
    throw GradleException("❌ key.properties bulunamadı: ${keystorePath.absolutePath}")
}


android {
    namespace = "com.rivorya.snorya"
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
        applicationId = "com.rivorya.snorya"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"]?.toString()
                ?: throw GradleException("storeFile eksik ya da null!")
            storeFile = file(storeFilePath)

            storePassword = keystoreProperties["storePassword"]?.toString()
                ?: throw GradleException("storePassword eksik!")
            keyAlias = keystoreProperties["keyAlias"]?.toString()
                ?: throw GradleException("keyAlias eksik!")
            keyPassword = keystoreProperties["keyPassword"]?.toString()
                ?: throw GradleException("keyPassword eksik!")
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
