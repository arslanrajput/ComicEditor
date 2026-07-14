import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    val rawBytes = keystorePropertiesFile.readBytes()
    val text = if (
        rawBytes.size >= 3 &&
        rawBytes[0] == 0xEF.toByte() &&
        rawBytes[1] == 0xBB.toByte() &&
        rawBytes[2] == 0xBF.toByte()
    ) {
        rawBytes.copyOfRange(3, rawBytes.size).toString(Charsets.UTF_8)
    } else {
        rawBytes.toString(Charsets.UTF_8)
    }
    text.byteInputStream().use { keystoreProperties.load(it) }
}

fun keystoreProperty(name: String): String? {
    return keystoreProperties.getProperty(name)?.trim()?.takeIf { it.isNotEmpty() }
}

fun isPlaceholder(value: String): Boolean {
    return value.startsWith("YOUR_") || value.contains("REPLACE", ignoreCase = true)
}

val releaseKeystoreFile: java.io.File? = keystoreProperty("storeFile")?.let { path ->
    val file = rootProject.file(path)
    if (file.exists()) file else null
}

val hasReleaseSigning: Boolean = listOf(
    "storePassword",
    "keyPassword",
    "keyAlias",
    "storeFile",
).all { key ->
    val value = keystoreProperty(key)
    value != null && !isPlaceholder(value)
} && releaseKeystoreFile != null

android {
    namespace = "com.comic.comic_editor"
    compileSdk = flutter.compileSdkVersion
    // NDK r28+ builds 16 KB ELF-aligned native libs (Google Play requirement).
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                keyAlias = keystoreProperty("keyAlias")!!
                keyPassword = keystoreProperty("keyPassword")!!
                storeFile = releaseKeystoreFile!!
                storePassword = keystoreProperty("storePassword")!!
            }
        }
    }

    defaultConfig {
        applicationId = "com.comic.comic_editor"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                throw GradleException(
                    "Release signing not configured. Edit android/key.properties with your " +
                        "real keystore passwords (not YOUR_STORE_PASSWORD placeholders), ensure " +
                        "key/comicEditor_app-keystore.jks exists, then run: flutter build appbundle --release"
                )
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // AGP 8.5.1+ zip-aligns uncompressed .so files on 16 KB boundaries for Play bundles.
    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }
}

flutter {
    source = "../.."
}
