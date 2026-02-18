allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    // Avoid forcing early evaluation of the Android app project which can
    // cause task resolution/order issues when the Gradle graph is built by
    // the Flutter tool. Evaluate subprojects lazily instead.

    // Disable unit tests for any subproject that provides Test tasks to
    // mitigate cross-drive compilation problems observed on Windows.
    tasks.withType<Test>().configureEach {
        enabled = false
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
