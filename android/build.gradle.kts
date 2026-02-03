buildscript {
    extra.apply {
        set("compileSdkVersion", 36)
        set("targetSdkVersion", 34)
        set("minSdkVersion", 21)
    }
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
        classpath("com.android.tools.build:gradle:8.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
