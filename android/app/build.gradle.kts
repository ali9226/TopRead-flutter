import java.io.FileInputStream
import java.util.Properties

// 读取签名配置
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // Flutter Gradle Plugin 必须在 Android & Kotlin 插件之后应用
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.topread.novel"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.topread.novel"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties.getProperty("storeFile") ?: "")
            storePassword = keystoreProperties.getProperty("storePassword") ?: ""
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: ""
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: ""
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // TODO 热更新引擎仅支持 arm64；排除插件附带的其他 ABI，避免商店误判设备兼容性。
            ndk {
                abiFilters.clear()
                abiFilters.add("arm64-v8a")
            }

            // 启用 R8 混淆
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // ✅ 保留 path_provider & flutter engine 原生 API，防止 Release crash
    buildFeatures {
        buildConfig = true
    }
}

// TODO Flutter 默认 ABI 集合会与 buildType 合并；发布变体再排除无配套引擎的插件架构。
androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        variant.packaging.jniLibs.excludes.addAll(
            listOf("armeabi", "armeabi-v7a", "x86", "x86_64", "mips", "mips64", "riscv64")
                .map { "**/$it/**" }
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("me.leolin:ShortcutBadger:1.1.22")
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

configurations.configureEach {
    resolutionStrategy.eachDependency {
        when ("${requested.group}:${requested.name}") {
            "androidx.activity:activity",
            "androidx.activity:activity-ktx" -> useVersion("1.10.1")
            "androidx.core:core",
            "androidx.core:core-ktx" -> useVersion("1.16.0")
        }
    }
}
