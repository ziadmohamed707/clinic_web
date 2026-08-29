# Known Issues & Technical Debt

This document catalogs security findings, technical debt, legacy files, architectural inconsistencies, performance bottlenecks, and missing tests identified in **PhysioOne**.

---

## 🚨 Risk Severity Classification

Issues are categorized by impact severity:
- 🔴 **Critical (P0)**: Severe security or data integrity vulnerability requiring immediate remediation.
- 🟠 **High (P1)**: Major architectural flaw or maintainability risk affecting stability.
- 🟡 **Medium (P2)**: Code duplication, legacy leftovers, or UI inconsistencies.
- 🔵 **Low (P3)**: Minor cleanup items, naming typos, or non-critical TODOs.

---

## 📋 Comprehensive Issues Catalog

### 🔴 Critical (P0)

#### 1. Plain-Text Password Storage & Custom Firestore Auth
- **Location**: `lib/ui/LoginPage/repository/auth_repository.dart:30` & `employees` collection
- **Description**: Authentication compares plain text `username` and `password` fields directly in Firestore document queries. Passwords are stored unhashed in Firestore.
- **Risk**: Any leak or excessive permission on `employees` collection exposes all employee credentials.
- **Remediation**: Migrate to Firebase Authentication SDK (`FirebaseAuth.instance.signInWithEmailAndPassword`) or apply salted password hashing (e.g. Argon2 / Bcrypt).

---

### 🟠 High (P1)

#### 2. Monolithic Screen Files Over 2,000 Lines
- **Location**: `lib/ui/ScheduleGridPade/ui/schedule_grid_pade.dart` (2,505 lines) & `lib/hr_system/ui/hr_screen.dart` (123 KB)
- **Description**: `ScheduleGridScreen` and `HRScreen` combine layout, direct Firestore stream subscriptions, local state management, timers, and dialog logic into single massive widget files.
- **Risk**: Hard to maintain, difficult to test, high probability of regression bugs.
- **Remediation**: Refactor large screens into small focused components and move business logic into BLoCs/Cubits.

#### 3. Low Unit & Widget Test Coverage (~5%)
- **Location**: `test/`
- **Description**: Only `widget_test.dart` exists in `test/`. Use cases, repositories, and BLoCs lack unit tests.
- **Risk**: Functional regressions when modifying package deduction rules or financial logic.
- **Remediation**: Write unit tests for domain use cases (`SaveAppointment`, `CancelAppointment`, `AddClient`) and BLoCs.

---

### 🟡 Medium (P2)

#### 4. Legacy Codebase Leftovers
- **Location**: `lib/main2.txt` (95 KB, 2,222 lines), `lib/ui/ScheduleGridPade/ui/schedule_grid_pade copy.dart` (133 KB), `lib/ui/HomePage/ui/home.txt` (5.9 KB).
- **Description**: Large backup files left behind during earlier codebase refactorings.
- **Risk**: Developer confusion and accidental imports.
- **Remediation**: Delete unused legacy files.

#### 5. Code Duplication in Location Service
- **Location**: `lib/core/app_consts/location_service.dart` & `lib/hr_system/ui/location_service.dart`
- **Description**: Identical `LocationService` class exists in two separate locations.
- **Remediation**: Remove `lib/hr_system/ui/location_service.dart` and use the canonical `lib/core/app_consts/location_service.dart`.

---

### 🔵 Low (P3)

#### 6. Directory Naming Typo
- **Location**: `lib/ui/ScheduleGridPade/`
- **Description**: Directory name uses `Pade` instead of `Page`.
- **Remediation**: Rename directory to `ScheduleGridPage` and update import paths.
