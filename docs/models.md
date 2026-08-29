# Models & Entities Documentation

This document describes all core domain entities, data models, DTOs, JSON serialization structures, and relationships within **PhysioOne**.

---

## 🗂️ Domain Entities vs. Data Models

PhysioOne maintains strict decoupling between pure immutable business domain entities (`lib/domain/entities/`) and database-aware data models (`lib/data/models/`):

```text
Domain Entity (Pure Dart / Equatable) 
       ▲                         │
       │ toEntity()              │ fromEntity()
       │                         ▼
Data Model (Map Serialization & Data Conversion)
       ▲                         │
       │ fromMap() / fromDoc()   │ toMap()
       │                         ▼
Storage Engines (Cloud Firestore Document / Local Hive Box)
```

---

## 📐 Models & Entities Detail

### 1. `UserModel`
- **Location**: `lib/ui/LoginPage/models/user_model.dart`
- **Fields**:
  - `docId`: `String?` (Firestore document ID)
  - `id`: `String?` (Employee Code e.g. "DR0004")
  - `username`: `String?`
  - `name`: `String?`
  - `email`: `String?`
  - `password`: `String?`
  - `role`: `String?` (`admin`, `desk`, etc.)
  - `position`: `String?`
  - `baseSalary`, `allowances`, `deductions`: `num?`
  - `department`: `String?`
  - `joinDate`: `DateTime?`
  - `attendance`: `List<dynamic>?`
  - `availableDays`: `List<String>?`
  - `annualLeaveQuota`, `sickLeaveQuota`: `int?`
  - `leaveRequests`, `allowanceRequests`: `List<dynamic>?`
  - `status`: `String?`

---

### 2. `Appointment` / `AppointmentModel`
- **Entity Location**: `lib/domain/entities/appointment.dart`
- **Model Location**: `lib/data/models/appointment_model.dart`
- **Fields**:
  - `id`: `String` (Format: `yyyy-MM-dd_TimeSlot_DoctorName`)
  - `patientName`: `String`
  - `doctorName`: `String`
  - `timeSlot`: `String` (e.g. `'09:00 AM'`)
  - `date`: `DateTime`
  - `phoneNumber`: `String?`
  - `clientId`: `int?`
  - `status`: `AppointmentStatus` (`booked`, `cancelled`, `completed`)
  - `serviceType`: `ServiceType` (`examination`, `consultation`, `recoveryFullBody`, `recoveryUpper`, `recoveryLower`, `cupping`, `followUpSession`)
  - `packageNameUsed`: `String?`
  - `packageCategoryUsed`: `String?`

#### JSON / Map Structure Example
```json
{
  "patient": "John Doe",
  "doctor": "Dr. Sarah",
  "timeSlot": "10:30 AM",
  "date": "2026-08-12T00:00:00.000",
  "phone": "01012345678",
  "clientId": 14,
  "status": "booked",
  "serviceType": "Examination",
  "packageNameUsed": "Physio 10 Sessions",
  "packageCategoryUsed": "Package Physio"
}
```

---

### 3. `Client` / `ClientModel`
- **Entity Location**: `lib/domain/entities/client.dart`
- **Model Location**: `lib/data/models/client_model.dart`
- **Fields**:
  - `id`: `int` (Auto-incrementing ID)
  - `name`: `String`
  - `age`: `int`
  - `phoneNumber`: `String`
  - `details`: `String?` (Medical notes & history)
  - `bookedPackages`: `List<ClientPackage>`

---

### 4. `ClientPackage` / `ClientPackageModel`
- **Entity Location**: `lib/domain/entities/client_package.dart`
- **Model Location**: `lib/data/models/client_package_model.dart`
- **Fields**:
  - `name`: `String` (e.g. `'Physio 10 Sessions'`)
  - `totalSessions`: `int`
  - `remainingSessions`: `int`
  - `category`: `String` (`Package Physio`, `Package Machines`, `Package Rehabilitation`)

---

### 5. `Doctor` / `DoctorModel`
- **Entity Location**: `lib/domain/entities/doctor.dart`
- **Model Location**: `lib/data/models/doctor_model.dart`
- **Fields**:
  - `id`: `String`
  - `name`: `String`
  - `availableDays`: `List<String>` (e.g. `["Sunday", "Monday", "Wednesday"]`)

---

### 6. `EmployeeModel`
- **Location**: `lib/hr_system/ui/employee_model.dart`
- **Fields**: Identical field structure to `UserModel` with explicit non-null defaults for HR management (`annualLeaveQuota = 15`, `sickLeaveQuota = 7`).
