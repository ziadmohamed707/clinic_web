# Troubleshooting Guide

This document documents common build, runtime, Hive storage, Firebase connection, and platform errors encountered during development, along with proven solutions.

---

## 🛠️ Common Issue Index

### 1. `HiveError: The Box 'x' is already open`
- **Symptom**: Unhandled Hive exception during hot restart or multiple initialization calls.
- **Cause**: Attempting to invoke `Hive.openBox()` when the box is already open in memory.
- **Solution**: Always use `initializeHive()` or check `Hive.isBoxOpen(boxName)` prior to opening:
  ```dart
  if (!Hive.isBoxOpen('boxName')) {
    await Hive.openBox('boxName');
  }
  ```

---

### 2. Hive Disk Box Corruption (`HiveError: Unknown frame type`)
- **Symptom**: App crashes on startup when loading Hive storage.
- **Cause**: Abrupt app termination during a binary disk write operation.
- **Solution**: In `lib/helper/initialize_hive.dart`, the app automatically handles this via `_openBoxSafely()`. To force clear corrupt Hive storage manually during dev:
  ```dart
  await clearAllHiveData();
  ```

---

### 3. Geofenced Attendance Check-In Rejection (`"You are too far from the clinic"`)
- **Symptom**: Staff member check-in fails with a distance error in meters.
- **Cause**: Device GPS coordinates are further than 200 meters from clinic coordinates (`30.049003, 31.240011`) or device location accuracy is low.
- **Solution**:
  1. Ensure location services / GPS are enabled on device.
  2. Verify that app location permissions are granted (`NSLocationWhenInUseUsageDescription` / `ACCESS_FINE_LOCATION`).
  3. Verify distance calculation using `LocationService.isUserWithinClinicRadius()`.

---

### 4. Firestore Security Permission Denied Errors
- **Symptom**: Firestore read/write operations throw `[cloud_firestore/permission-denied]`.
- **Cause**: Firestore security rules enforcing `request.auth != null` while app uses custom document field queries instead of Firebase Auth tokens.
- **Solution**: Update Firestore rules to permit authenticated application requests or complete migration to official Firebase Auth SDK.

---

### 5. Web Subdirectory Routing 443 / 404 Assets
- **Symptom**: Assets or routes fail to resolve on Web deployment.
- **Cause**: Incorrect base URL in `web/index.html`.
- **Solution**: Verify base tag `<base href="/clinic_web/">` matches your web server subdirectory path.
