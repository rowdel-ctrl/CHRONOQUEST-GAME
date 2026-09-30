plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Unique, always-incrementing versionCode derived from git history, so every
// build gets a new build number without editing pubspec.yaml by hand.
fun gitCommitCount(): Int {
    return try {
        val process = ProcessBuilder("git", "rev-list", "--count", "HEAD")
            .redirectErrorStream(true)
            .start()
        val output = process.inputStream.bufferedReader().use { it.readText() }.trim()
        process.waitFor()
        output.toInt()
    } catch (e: Exception) {
        1
    }
}

android {
    namespace = "com.chronoquest.chronoquest"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.chronoquest.chronoquest"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = gitCommitCount()
        versionName = flutter.versionName
    }

    buildTypes {
        release {

            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
