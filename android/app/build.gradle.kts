plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.smart_kisan"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.smart_kisan"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Ensure Flutter tool can find the assembled APK by copying it to the
// project's root `build/app/outputs/flutter-apk` after assembleDebug.
// This helps when Gradle produces the APK under `android/app/build/...`.
tasks.register("copyDebugApkToRoot") {
    doLast {
        // possible APK locations inside the app module
        val apkCandidates = listOf(
            file("$buildDir/outputs/flutter-apk/app-debug.apk"),
            file("$buildDir/outputs/apk/debug/app-debug.apk")
        )

        // Flutter project root is the parent of the Android root (../)
        val androidRoot = rootProject.rootDir
        val flutterRoot = androidRoot.parentFile ?: androidRoot
        val destDir = File(flutterRoot, "build/app/outputs/flutter-apk")

        val src = apkCandidates.firstOrNull { it.exists() }
        if (src != null) {
            destDir.mkdirs()
            copy {
                from(src)
                into(destDir)
                rename { "app-debug.apk" }
            }
            println("[build] Copied ${src.absolutePath} -> ${destDir.absolutePath}")
        } else {
            println("[build] APK not found in any candidate locations; skipping copy.")
        }
    }
}

// Attach the copy task to any Assemble Debug tasks without assuming the task
// exists at configuration time.
tasks.matching { t -> t.name == "assembleDebug" || t.name.endsWith("Debug") }
    .configureEach {
        finalizedBy("copyDebugApkToRoot")
    }
