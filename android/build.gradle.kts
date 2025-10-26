// Add the buildscript block for configuring plugins
buildscript {
    repositories {
        google() // Required for Google services
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.4.2") // Android Gradle Plugin
        classpath("com.google.gms:google-services:4.3.15") // Google Services Plugin
    }
}

// Configure all projects
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Custom build directory configuration
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}