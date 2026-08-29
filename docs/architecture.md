# Architecture Documentation

This document explains the overall software architecture, design patterns, core layers, data flows, and subsystem responsibilities within **PhysioOne**.

---

## 🏛️ Architectural Style Overview

PhysioOne uses a **Hybrid Clean Architecture** model combined with an **Offline-First Dual-Source Repository Pattern**.

### Architectural Highlights
- **Clean Architecture Separation**: Clean separation between **Domain** (business logic/entities/usecases), **Data** (models/repositories/sources), and **Presentation** (UI/BLoC).
- **Feature-Based Presentation Packaging**: UI components, pages, widgets, and BLoCs are structured under `lib/ui/<FeatureName>/` and `lib/hr_system/`.
- **Offline-First Cache-First Strategy**: Reads query local Hive boxes first before checking Firestore; writes immediately persist to local Hive storage and asynchronously sync to Cloud Firestore.
- **Reactive State Flow**: BLoCs handle state transformations using RxDart streams and `flutter_bloc` events.

---

## 📐 Layer Breakdown & Responsibilities

```mermaid
flowchart TD
    subgraph Presentation ["Presentation Layer (lib/ui & lib/hr_system)"]
        Widgets[Flutter Screens & Custom Widgets]
        Blocs[BLoCs & Controllers]
    end

    subgraph Domain ["Domain Layer (lib/domain)"]
        Entities[Domain Entities: Client, Doctor, Appointment, ClientPackage]
        UseCases[Use Cases: SaveAppointment, CancelAppointment, AddClient...]
        RepoInterfaces[Repository Interfaces: AppointmentRepository...]
    end

    subgraph Data ["Data Layer (lib/data & lib/helper)"]
        Models[Data Models: AppointmentModel, ClientModel...]
        RepoImpls[Repository Implementations]
        HiveHelper[Hive Storage Helper & Local Storage Service]
    end

    subgraph External ["External Infrastructure"]
        Firestore[(Cloud Firestore)]
        HiveBoxes[(Hive Storage Boxes)]
        Geo[Geolocator API]
    end

    Widgets --> Blocs
    Blocs --> UseCases
    UseCases --> RepoInterfaces
    RepoImpls ..|> RepoInterfaces
    RepoImpls --> Models
    RepoImpls --> HiveBoxes
    RepoImpls --> Firestore
    Widgets --> Geo
```

---

## 🔄 End-to-End Data Flow

### 1. Data Retrieval Flow (Read Operation)
```text
UI Component -> BLoC Event -> Use Case -> Repository Implementation
  -> Check Hive Box -> Hive hit? 
        ├─ YES: Return mapped Domain Entity immediately
        └─ NO: Fetch from Firestore -> Cache in Hive -> Return mapped Domain Entity
```

### 2. Data Persistence Flow (Write Operation)
```text
UI Form -> Submit Event -> BLoC -> Use Case Execution (e.g. SaveAppointment)
  -> Repository Implementation
        ├─ 1. Write to local Hive Box (Instant response)
        └─ 2. Write to Cloud Firestore collection
```

---

## 🧩 Architectural Inconsistencies & Legacy Notes

During analysis, the following architectural inconsistencies were identified:

1. **Mixed Clean Architecture & Monolithic Widgets**: While `Appointment`, `Client`, and `Doctor` domains follow Clean Architecture (`lib/domain/` & `lib/data/`), several features (such as `ScheduleGridScreen` in `lib/ui/ScheduleGridPade/ui/schedule_grid_pade.dart` and `HRScreen` in `lib/hr_system/ui/hr_screen.dart`) combine direct Firestore streams, Hive calls, UI layout, and timers inside large stateful widgets.
2. **Direct Firestore Access in Presentation**: `EmployeeService` in `lib/hr_system/ui/employee_service.dart` directly queries `FirebaseFirestore.instance` without using a domain repository abstraction.
3. **Legacy Backup Code**: `lib/main2.txt` (2,222 lines) and `schedule_grid_pade copy.dart` (133 KB) remain in the codebase as unused legacy files.

---

## 🎯 Architectural Value Justification

- **Why Domain Entities exist**: To decouple pure business definitions (`Appointment`, `ClientPackage`) from database structure differences.
- **Why Use Cases exist**: To encapsulate complex rules (e.g., `SaveAppointment` automatically decrements available package sessions for clients when booking follow-ups or specific service types).
- **Why Repositories exist**: To provide a unified API abstraction allowing offline caching via Hive and online cloud sync via Firestore.
