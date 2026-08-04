plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ilactakip.ilac_takip"
    compileSdk = flutter.compileSdkVersion
    // CI'da sabit NDK sürümü yoksa build kırılmasın; plugin gerekirse Flutter seçer.
    // ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications için zorunlu
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.ilactakip.ilac_takip"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Yayın öncesi kendi keystore imzanızı bağlayın.
            signingConfig = signingConfigs.getByName("debug")
            // Önce APK üretimi; R8 sorunları ayrıştırıldıktan sonra tekrar açılır.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
