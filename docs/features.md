# Feature Documentation

This document describes all primary business features implemented within **PhysioOne**, documenting purpose, screens, controllers, repositories, data flows, and business rules.

---

## 📋 Feature Summary Matrix

| Feature | Entry Point File | State Management | Primary Storage | Roles Allowed |
|---|---|---|---|---|
| **1. Authentication & Session** | `lib/ui/LoginPage/ui/login_page.dart` | `AuthBloc` | Hive (`userSession`) + Firestore (`employees`) | All |
| **2. Interactive Schedule Grid** | `lib/ui/ScheduleGridPade/ui/schedule_grid_pade.dart` | `ScheduleGridBloc` | Hive (`appointments`) + Firestore | All |
| **3. Client Management** | `lib/ui/ClientListPage/ui/client_list_page.dart` | Stateful / Local | Hive (`clients`) + Firestore | Admin, Desk |
| **4. Client Registration** | `lib/ui/AddClientPage/ui/add_client_page.dart` | `ScheduleGridBloc` | Hive (`clients`) + Firestore | Admin, Desk |
| **5. Doctor Management** | `lib/ui/ManageDoctorPage/ui/manage_doctors_page.dart` | Stateful / Local | Hive (`doctors`) + Firestore | Admin |
| **6. System User Management** | `lib/ui/ManageUserPage/ui/manage_users_page.dart` | `ManageUsersBloc` | Hive (`users`) + Firestore | Admin |
| **7. Financial Management** | `lib/ui/FinancialManagementPage/ui/financial_management_page.dart` | Stateful / Local | Hive + Firestore | Admin, Desk |
| **8. HR & Geofenced Check-in** | `lib/hr_system/ui/hr_screen.dart` | Stateful / Stream | Firestore (`employees`) | All Employees |
| **9. Billing & Service Requests** | `lib/ui/billPaymentScreen/ui/bill_notification_screen.dart` | Stateful / Local | Firestore | Admin |

---

## 🔍 Detailed Feature Specifications

### 1. Authentication & Session Management
- **Purpose**: Authenticates clinic staff against the Firestore `employees` collection and maintains persistent login state via Hive (`userSession`).
- **User Flow**:
  ```text
  App Startup -> AuthStartupCheckRequested -> Hive Check -> Found? 
    ├─ YES: Authenticated -> Navigate to HomePage (ScheduleGridScreen)
    └─ NO: Unauthenticated -> Display LoginScreen -> Form Submission (LoginSubmitted)
          -> Validate username & password against Firestore 'employees'
          -> Save to Hive box 'userSession' -> Update AuthState -> Display ScheduleGridScreen
  ```
- **Business Rules**: Plaintext password matching on `username` and `password` fields; role string (`admin`, `desk`, doctor, etc.) controls UI privileges.

---

### 2. Interactive Schedule Grid (`ScheduleGridScreen`)
- **Purpose**: Serves as the primary operational dashboard for clinic staff. Displays doctor availability per day and 19 daily time slots (`09:00 AM` to `12:00 AM`).
- **Core Capabilities**:
  - Date Picker: Navigate to any day to view scheduled appointments.
  - Doctor Filtering: Automatically filters doctors whose `availableDays` list includes the selected weekday.
  - Appointment Booking: Tap any empty matrix cell to book an appointment.
  - Package Session Deduction: Automatic deduction of sessions when booking follow-ups or package services (`SaveAppointment` use case).
  - Appointment Cancellation: Cancelling a booked appointment restores the session to the client's package (`CancelAppointment` use case).
  - WhatsApp Confirmation: Generates localized Arabic/English WhatsApp reminder templates with map link `https://maps.app.goo.gl/UPxFe3tbG6McKAVZA`.

---

### 3. Client Management & Package System
- **Purpose**: Tracks client personal information (name, phone, age, notes) and active service package subscriptions.
- **Service Categories**:
  - `Package Physio` (Physical Therapy)
  - `Package Machines` (Specialized Device Therapy)
  - `Package Rehabilitation` (Rehab Programs)
- **Business Logic**: Each client maintains a list of `bookedPackages` (`name`, `totalSessions`, `remainingSessions`, `category`). Auto-incrementing Client ID starts from metadata counter in Hive/Firestore.

---

### 4. HR & Geofenced Attendance System (`HRScreen`)
- **Purpose**: Provides employee self-service and management capabilities, including GPS-bounded check-in/out, leave requests, allowance requests, and salary payslips.
- **Geofence Parameters**:
  - **Clinic Coordinates**: Latitude `30.049003`, Longitude `31.240011`
  - **Check-in Radius**: `200.0 meters`
- **Check-in Flow**:
  ```text
  User taps Check-in -> Request Location Permissions -> Fetch GPS Position via Geolocator
    -> Calculate Distance to Clinic Coordinates -> Distance <= 200m?
          ├─ YES: Append timestamp & location address to employee 'attendance' array in Firestore
          └─ NO: Reject check-in & display error distance in meters
  ```

---

### 5. Financial Management
- **Purpose**: Calculates real-time financial statistics based on client package purchases, session fees, and operational expenses.
- **Metrics Tracked**:
  - Daily & Monthly Revenue
  - Outstanding Bills & Expenses
  - Package Sales Volume
