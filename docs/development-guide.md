# Developer Onboarding & Development Guide

This document serves as a practical onboarding guide for new software developers joining the **PhysioOne** project.

---

## 🚀 Quick Onboarding FAQ

### 1. What is this project?
PhysioOne is a multiplatform Flutter clinic management portal that enables staff to handle doctor schedules, client registrations, service packages, financial statistics, and GPS-bounded employee attendance check-ins.

---

### 2. How do I set up my environment?
1. Clone the repository into your workspace.
2. Install **Flutter SDK 3.29+** and **Dart SDK 3.7+**.
3. Install **VS Code** with Flutter and Dart extensions (or **Android Studio**).
4. Run dependency resolution:
   ```bash
   flutter pub get
   ```

---

### 3. How do I run the application locally?

#### Launch on Chrome (Web)
```bash
flutter run -d chrome
```

#### Launch on Android Emulator
```bash
flutter run -d emulator-5554
```

---

### 4. Where should I add new code?

```text
Task: Add a new domain entity / model / repository
  ├── Entity -> lib/domain/entities/
  ├── UseCase -> lib/domain/usecases/
  ├── Data Model -> lib/data/models/
  └── Repository -> lib/data/repositories/

Task: Add a new screen / feature module
  ├── Presentation Folder -> lib/ui/NewFeaturePage/
  ├── Screen Widget -> lib/ui/NewFeaturePage/ui/new_feature_page.dart
  └── BLoC / Cubit -> lib/ui/NewFeaturePage/bloc/

Task: Add shared UI token / color
  └── Token -> lib/core/app_colors.dart
```

---

### 5. How do I register a new Hive box or adapter?
1. Edit `lib/helper/initialize_hive.dart`.
2. Add adapter registration checking `Hive.isAdapterRegistered(typeId)`. Assign a unique `typeId` (e.g. `51+`).
3. Call `await _openBoxSafely('your_box_name')`.

---

### 6. What coding standards & rules must I follow?
- **Do not bypass UseCases in BLoCs**: Pass business logic through `lib/domain/usecases/`.
- **Maintain local Hive cache fallback**: Always update local Hive boxes alongside Firestore database updates.
- **Do not commit unhashed passwords**: If working on auth, hash passwords before database queries.
