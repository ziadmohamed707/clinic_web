# Project Configuration Documentation

This document describes all environment configurations, app constants, Firebase options, geofence coordinates, and build flags in **PhysioOne**.

---

## ⚙️ App Constants (`lib/core/app_consts/app_consts.dart`)

```dart
class AppConsts {
  static const String appName = 'Physio One';
  static const String appVersion = '1.0.0';
  static const String apiBaseUrl = 'https://api.example.com';
  static const String supportEmail = 'support@example.com';

  // Clinic Location for HR Geofenced Attendance
  static const double clinicLatitude = 30.049003;
  static const double clinicLongitude = 31.240011;
  static const double clinicCheckInRadiusMeters = 200.0; // 200 meters radius
}
```

---

## 📍 Clinic Geofence Parameters

- **Clinic Latitude**: `30.049003`
- **Clinic Longitude**: `31.240011`
- **Check-in Radius**: `200.0 meters`
- **Map Location URL**: `https://maps.app.goo.gl/UPxFe3tbG6McKAVZA`
- **Clinic Support Phone**: `+20 102 124 6044`

---

## 📅 System Time Slots (`kTimeSlots`)

The appointment grid is divided into 19 standard 45-to-50-minute slots:
`09:00 AM`, `09:50 AM`, `10:40 AM`, `11:30 AM`, `12:20 PM`, `01:10 PM`, `02:00 PM`, `02:50 PM`, `03:40 PM`, `04:30 PM`, `05:20 PM`, `06:10 PM`, `07:00 PM`, `07:50 PM`, `08:40 PM`, `09:30 PM`, `10:20 PM`, `11:10 PM`, `12:00 AM`.

---

## 🔥 Firebase Configuration (`lib/firebase_options.dart`)

- **Project ID**: `<FIREBASE_PROJECT_ID>` (`physioone-74446`)
- **Messaging Sender ID**: `<SENDER_ID>` (`419143087841`)
- **Android App ID**: `<ANDROID_APP_ID>` (`1:419143087841:android:6b9e5d627b23913bab29a0`)
- **iOS App ID**: `<IOS_APP_ID>` (`1:419143087841:ios:d09050b56d04dc0dab29a0`)
- **Web App ID**: `<WEB_APP_ID>` (`1:419143087841:web:2bca69c292221616ab29a0`)
