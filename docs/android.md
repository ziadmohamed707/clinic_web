# Android Configuration Documentation

This document describes the Android native project setup, Gradle build system, SDK targets, permissions, and build instructions for **PhysioOne**.

---

## 🤖 Android Configuration Overview

- **Package / Application ID**: `package="com.physioone.clinic"`
- **Gradle Plugin**: `dev.flutter.flutter-gradle-plugin` (Kotlin DSL `build.gradle.kts`)
- **Google Services Plugin**: `com.google.gms.google-services`
- **Java Compatibility**: `JavaVersion.VERSION_11`
- **Target SDK**: Inherited from Flutter SDK (`flutter.targetSdkVersion`)
- **Min SDK**: Inherited from Flutter SDK (`flutter.minSdkVersion`)
- **Compile SDK**: Inherited from Flutter SDK (`flutter.compileSdkVersion`)

---

## 📁 Key Android Project Files

1. `android/build.gradle.kts`: Root Gradle script configuring repositories and buildscript plugins.
2. `android/app/build.gradle.kts`: App module build script declaring plugins, SDKs, and debug signing configs.
3. `android/app/google-services.json`: Firebase Android configuration file.
4. `android/app/src/main/AndroidManifest.xml`: Android manifest declaring hardware features and permissions.

---

## 🔒 Declared Android Permissions (`AndroidManifest.xml`)

```xml
<!-- Internet & Network State -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<!-- Geolocation for HR Geofenced Attendance -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

---

## 🚀 Building Android Artifacts

### Debug APK
```bash
flutter build apk --debug
```

### Release APK
```bash
flutter build apk --release
```

### Release App Bundle (AAB for Google Play)
```bash
flutter build appbundle --release
```
