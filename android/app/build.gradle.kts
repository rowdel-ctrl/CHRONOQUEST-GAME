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

// Two builds from the same code:
//   student (the default, what goes on the landing page): no Test Mode.
//   tester: has the Test Mode switch, its own app id and its own name, so it can
//   sit on a phone next to the student app. Make it with
//     flutter build apk --release --target-platform android-arm64 \
//       --dart-define=TEST_MODE=true --android-project-arg=testBuild=true
// Both flags go together: the define turns the switch on inside the game, the
// project argument gives the app its own id, name and version suffix.
val testBuild = project.findProperty("testBuild")?.toString() == "true"

android {
    namespace = "com.chronoquest.chronoquest"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = if (testBuild) "com.chronoquest.chronoquest.test" else "com.chronoquest.chronoquest"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = gitCommitCount()
        versionName = "${flutter.versionName}${if (testBuild) "-test" else ""}"
        manifestPlaceholders["appLabel"] = if (testBuild) "ChronoQuest TEST" else "chronoquest"
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
