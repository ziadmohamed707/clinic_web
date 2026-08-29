# Project Structure Documentation

This document describes the actual folder and file layout of **PhysioOne**, detailing directory purposes, key files, and misplaced legacy artifacts.

---

## 📁 Root Directory Layout

```text
physioone/ (clinic_web-1)
├── android/                        # Android native project & Gradle build files
├── assets/                         # Static assets (images, logos)
├── build/                          # Generated compilation output (ignored by git)
├── docs/                           # Technical documentation suite
├── ios/                            # iOS native Xcode project & Podfile
├── lib/                            # Main application Dart source code
├── linux/                          # Linux native desktop application wrapper
├── macos/                          # macOS native desktop application wrapper
├── test/                           # Test suite directory
├── web/                            # Web platform wrapper & HTML template
├── windows/                        # Windows native desktop application wrapper
├── analysis_options.yaml           # Dart linter static analysis configuration
├── firebase.json                   # FlutterFire CLI project configuration
├── pubspec.lock                    # Locked dependency version tree
├── pubspec.yaml                    # Package dependencies & asset configuration
└── README.md                       # Repository original readme file
```

---

## 📂 Source Code Directory Breakdown (`lib/`)

```text
lib/
├── core/                           # Core cross-cutting utilities & design tokens
│   ├── app_colors.dart             # AppColors design system palette
│   ├── app_consts/                 # System constants, clinic coordinates, time slots
│   │   ├── app_consts.dart         # Global constants & WhatsApp template text
│   │   └── location_service.dart   # Geolocator radius verification logic (200m)
│   ├── errors/                     # Failure hierarchy definitions
│   │   └── failures.dart           # Failure classes (ServerFailure, CacheFailure, etc.)
│   └── usecases/                   # Abstract UseCase definition
│       └── usecase.dart            # Base Callable UseCase contract
│
├── data/                           # Data layer implementations
│   ├── models/                     # Data transfer objects & Firestore mappers
│   │   ├── appointment_model.dart  # Appointment Data Model
│   │   ├── client_model.dart       # Client Data Model
│   │   ├── client_package_model.dart # Client Package Data Model
│   │   └── doctor_model.dart       # Doctor Data Model
│   └── repositories/               # Repository implementations (Hive + Firestore)
│       ├── appointment_repository_impl.dart # Appointment repository implementation
│       ├── client_repository_impl.dart      # Client repository implementation
│       └── doctor_repository_impl.dart      # Doctor repository implementation
│
├── domain/                         # Pure business logic layer
│   ├── entities/                   # Domain core business objects
│   │   ├── appointment.dart        # Appointment entity & enums
│   │   ├── client.dart             # Client entity
│   │   ├── client_package.dart     # ClientPackage entity
│   │   └── doctor.dart             # Doctor entity
│   ├── repositories/               # Repository interface contracts
│   │   ├── appointment_repository.dart
│   │   ├── client_repository.dart
│   │   └── doctor_repository.dart
│   └── usecases/                   # Business use case implementations
│       ├── add_client.dart         # Register new client & assign auto-increment ID
│       ├── cancel_appointment.dart # Cancel appointment & restore package session
│       ├── get_all_clients.dart    # Fetch all clients
│       ├── get_appointments.dart   # Fetch appointments for date
│       ├── get_available_doctors.dart # Filter doctors by working day
│       ├── get_clients.dart        # Fetch client list
│       ├── get_doctors.dart        # Fetch doctor list
│       └── save_appointment.dart   # Book appointment & deduct package sessions
│
├── helper/                         # Storage initialization & helper utilities
│   ├── edit_cell.dart              # Cell editor dialog helper for schedule grid
│   ├── edit_client.dart            # Client editing dialog helper
│   ├── initialize_hive.dart        # Hive initialization & local storage service
│   └── shared_pref.dart            # SharedPreferences helper wrapper
│
├── hr_system/                      # Human Resources & Attendance Module
│   └── ui/                         # HR UI screens & models
│       ├── employee_model.dart     # Employee Data Model (salary, attendance, leaves)
│       ├── employee_service.dart    # Direct Firestore operations for employees
│       ├── hr_screen.dart          # HR Dashboard, attendance check-in, payroll view
│       └── location_service.dart   # HR specific geolocation helper (duplicate copy)
│
├── ui/                             # Presentation Features Packaging
│   ├── AddClientPage/              # Add Client Screen (`add_client_page.dart`)
│   ├── ClientListPage/             # Client List Management (`client_list_page.dart`)
│   ├── FinancialManagementPage/    # Revenue & Expenses Screen (`financial_management_page.dart`)
│   ├── HomePage/                   # Main Home wrapper (`home_page.dart`)
│   ├── LoginPage/                  # Authentication Module (BLoC, Model, Repository, UI)
│   ├── ManageDoctorPage/           # Manage Doctor Profiles (`manage_doctors_page.dart`)
│   ├── ManageUserPage/             # Manage System Users (`manage_users_page.dart`)
│   ├── PackagesPage/               # Service Package Plans (`packages_page.dart`)
│   ├── ScheduleGridPade/           # Schedule Grid Matrix Screen & Widgets
│   └── billPaymentScreen/          # Billing notifications & System Services
│
├── utils/                          # Utility adapters
│   └── hive_adapters.dart          # Custom TimestampAdapter (typeId 50) for Hive
│
├── widgets/                        # Shared global UI widgets
│   └── state_card.dart             # Modern Stats Dashboard Card widget
│
├── firebase_options.dart           # Generated FlutterFire configuration options
├── main.dart                       # Application entry point
└── main2.txt                       # [LEGACY] Unused 2,222-line monolithic main file
```

---

## 🔍 Identified Misplaced & Legacy Files

1. **`lib/main2.txt`**: Legacy monolithic main file (95.2 KB, 2,222 lines) created during early development before modular refactoring. Should be removed.
2. **`lib/ui/ScheduleGridPade/ui/schedule_grid_pade copy.dart`**: Backup copy (133 KB) of `schedule_grid_pade.dart`. Should be removed.
3. **`lib/ui/HomePage/ui/home.txt`**: Plain text backup (5.9 KB) of old home screen code.
4. **`lib/hr_system/ui/location_service.dart`**: Duplicated location service implementation. The canonical location service resides in `lib/core/app_consts/location_service.dart`.
5. **Directory Naming Typo**: `lib/ui/ScheduleGridPade` uses `Pade` instead of `Page`.
