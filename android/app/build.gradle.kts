plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    kotlin("android")

}

android {
    namespace = "com.example.climbx_fe"
    compileSdk = 35  // API 35 (네이버 지도 요구사항)
    ndkVersion = "27.0.12077973"  // 네이버 지도 요구사항

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.climbx_fe"
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Include Android resources in unit tests
    testOptions {
        unitTests.isIncludeAndroidResources = true
    }

    // Lint settings: disable all reports and prevent abort
    lint {
        abortOnError = false
        checkReleaseBuilds = false
        xmlReport = false
        htmlReport = false
        textReport = false
    }
}

flutter {
    source = "../.."
}

// Disable problematic Gradle tasks after evaluation
afterEvaluate {
    // Disable all lint tasks (lintDebug, lintRelease, etc.)
    tasks.matching { it.name.startsWith("lint", ignoreCase = true) }
        .configureEach { enabled = false }

    // Disable all unit test tasks
    tasks.matching { it.name.contains("test", ignoreCase = true) }
        .configureEach { enabled = false }

    // Disable outgoingVariants task
    tasks.matching { it.name.equals("outgoingVariants", ignoreCase = true) }
        .configureEach { enabled = false }
}
