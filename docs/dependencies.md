# Dependencies Analysis Documentation

This document categorizes, evaluates, and documents all direct and dev dependencies listed in `pubspec.yaml`.

---

## 📚 Categorized Dependencies List

### 1. Framework & Core
- `flutter` (SDK): Core Flutter framework (`sdk: flutter`).

### 2. State Management & Streams
- `bloc` (`^9.0.0`): Core BLoC business logic library.
- `flutter_bloc` (`^9.1.1`): Flutter widgets for BLoC integration (`BlocBuilder`, `BlocProvider`, `RepositoryProvider`).
- `rxdart` (`^0.28.0`): Reactive extensions for Dart (`BehaviorSubject` in `AuthRepository`).

### 3. Firebase & Backend Infrastructure
- `firebase_core` (`^3.14.0`): Core Firebase plugin initialization.
- `cloud_firestore` (`^5.6.9`): Cloud NoSQL database SDK.
- `firebase_auth` (`^5.6.0`): Firebase Authentication plugin (included in pubspec).

### 4. Local Offline Caching & Storage
- `hive_flutter` (`^1.1.0`): Lightweight fast binary key-value database for Flutter.
- `shared_preferences` (`^2.5.3`): Key-value preference storage.

### 5. Geolocation & HR Check-in
- `geolocator` (`^11.0.0`): Device GPS positioning and distance calculation (`Geolocator.distanceBetween`).
- `geocoding` (`^3.0.0`): Reverse geocoding lat/lng coordinates to street addresses (`placemarkFromCoordinates`).

### 6. Utilities & Functional Helpers
- `dartz` (`^0.10.1`): Functional programming constructs (`Either<Failure, Success>`).
- `equatable` (`^2.0.7`): Simplifies value comparisons in entities and states without overriding `==` manually.
- `intl` (`^0.20.2`): Date formatting (`DateFormat('yyyy-MM-dd')`) and number formatting.
- `uuid` (`^4.5.1`): Unique identifier generation.
- `url_launcher` (`^6.3.1`): Launching WhatsApp links (`https://wa.me/...`) and google map URLs.
- `collection` (`^1.18.0`): Collection operations (`firstWhereOrNull`).
- `restart_app` (`^1.3.2`): Application restart utility.
- `cupertino_icons` (`^1.0.8`): Cupertino icon fonts for iOS styling.

---

## 🛠️ Development Dependencies (`dev_dependencies`)

- `flutter_test` (SDK): Flutter unit and widget testing framework.
- `flutter_lints` (`^5.0.0`): Recommended lint rules for Flutter code quality.

---

## ⚠️ Package Observations & Maintenance Notes

1. **Unused / Indirect Packages**: `firebase_auth` is imported in `pubspec.yaml`, but authentication logic currently queries Firestore `employees` directly. Keep package for recommended auth migration.
2. **Hive Package Maintenance**: `hive_flutter: ^1.1.0` is stable and used extensively. Maintain custom adapter type IDs (`TimestampAdapter` = `50`).
