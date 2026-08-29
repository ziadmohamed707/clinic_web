# iOS Configuration Documentation

This document describes the iOS project configuration, Xcode setup, iOS permissions, CocoaPods configuration, and iOS build procedures for **PhysioOne**.

---

## 🍎 iOS Configuration Overview

- **Bundle Display Name**: `Clinic Management System`
- **Bundle Identifier**: `$(PRODUCT_BUNDLE_IDENTIFIER)`
- **Target Deployment**: iOS 12.0+
- **CocoaPods Manager**: `ios/Podfile`

---

## 🔒 iOS Permissions (`ios/Runner/Info.plist`)

PhysioOne requires explicit location permissions to support the HR GPS check-in feature:

```xml
<!-- Geolocation Permissions for Attendance Verification -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to your location to verify attendance at the workplace.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to your location to verify attendance at the workplace.</string>
```

---

## 📦 CocoaPods & Native Dependencies (`ios/Podfile`)

The `Podfile` automatically includes Firebase iOS Pods (`Firebase/Core`, `Firebase/Firestore`) and Flutter plugin Pods (`geolocator_apple`, `hive`).

---

## 🚀 Building iOS Artifacts

### 1. Install iOS CocoaPods
```bash
cd ios
pod install
cd ..
```

### 2. Build iOS Release Bundle
```bash
flutter build ios --release
```

### 3. Generate IPA for TestFlight / App Store
```bash
flutter build ipa --release
```
