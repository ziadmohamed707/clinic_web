# Build & Release Guide

This document provides step-by-step instructions for building, packaging, and deploying **PhysioOne** across Web, Android, iOS, and Desktop platforms.

---

## 🛠️ Prerequisites & Setup

Ensure the following tools are installed:
- Flutter SDK `3.29.x` (Channel stable)
- Dart SDK `3.7.x`
- Xcode 15+ (for iOS/macOS)
- Android Studio with Android SDK 34 (for Android)
- Google Chrome (for Web deployment)

---

## 📦 Code Generation & Dependency Installation

Run dependencies fetch before compilation:

```bash
flutter pub get
```

---

## 🌐 Web Build & Deployment (GitHub Pages / Subdirectory)

Note: `web/index.html` is configured with `<base href="/clinic_web/">` for subdirectory hosting.

### 1. Build Web Artifacts
```bash
flutter build web --release --base-href "/clinic_web/"
```

### 2. Deploy Web Build
Upload the contents of `build/web/` to your web server, Apache `.htaccess`, or GitHub Pages deployment repository.

---

## 🤖 Android Build Guide

### 1. Build Debug APK
```bash
flutter build apk --debug
```

### 2. Build Production Release APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### 3. Build App Bundle for Google Play
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

---

## 🍎 iOS Build & TestFlight Deployment

### 1. Pre-build Setup
```bash
cd ios
pod install
cd ..
```

### 2. Build Release Bundle
```bash
flutter build ios --release
```

### 3. Archive & Upload via Xcode
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select **Product > Archive**.
3. Validate and upload archive to **App Store Connect / TestFlight**.

---

## 💻 Desktop Builds

### Windows Desktop
```bash
flutter build windows --release
```

### macOS Desktop
```bash
flutter build macos --release
```
