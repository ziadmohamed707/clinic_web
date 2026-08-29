# API & Database Operations Documentation

This document documents all Cloud Firestore database operations, queries, data transformations, and endpoints utilized by **PhysioOne**.

---

## 🔌 API Communication Overview

PhysioOne relies directly on **Google Cloud Firestore SDK** (`cloud_firestore: ^5.6.9`) instead of custom REST HTTP endpoints. All data requests execute over Firestore WebSocket/gRPC streams.

---

## 🗄️ Firestore Operations Specification

### 1. Authentication Query
- **Collection**: `employees`
- **Method**: `.where('username', '==', username).where('password', '==', password).limit(1).get()`
- **Purpose**: Validates staff credentials and retrieves user document ID.
- **Repository**: `AuthRepository.signIn()` (`lib/ui/LoginPage/repository/auth_repository.dart:27`)
- **Response**: Array containing matching employee document.

---

### 2. Save Appointment
- **Collection**: `appointments`
- **Document Path**: `appointments/{appointmentId}`
- **Method**: `.doc(id).set(appointmentMap)`
- **Purpose**: Creates or updates an appointment record.
- **Repository**: `AppointmentRepositoryImpl.saveAppointment()` (`lib/data/repositories/appointment_repository_impl.dart:23`)

---

### 3. Get Appointment by ID
- **Collection**: `appointments`
- **Document Path**: `appointments/{id}`
- **Method**: `.doc(id).get()`
- **Purpose**: Fallback retrieval if appointment is missing from local Hive cache.
- **Repository**: `AppointmentRepositoryImpl.getAppointment()` (`lib/data/repositories/appointment_repository_impl.dart:42`)

---

### 4. Delete / Cancel Appointment
- **Collection**: `appointments`
- **Document Path**: `appointments/{id}`
- **Method**: `.doc(id).delete()`
- **Purpose**: Removes cancelled or deleted appointment document.
- **Repository**: `AppointmentRepositoryImpl.deleteAppointment()` (`lib/data/repositories/appointment_repository_impl.dart:77`)

---

### 5. Save / Update Client
- **Collection**: `clients`
- **Document Path**: `clients/{clientId}`
- **Method**: `.doc(id).set(clientMap)`
- **Purpose**: Creates or updates client profile and booked package session counters.
- **Repository**: `ClientRepositoryImpl.saveClient()` (`lib/data/repositories/client_repository_impl.dart:22`)

---

### 6. Auto-Increment Client Metadata Counter
- **Collection**: `clients`
- **Document Path**: `clients/metadata`
- **Method**: `.doc('metadata').set({'lastId': newId})`
- **Purpose**: Tracks highest assigned integer ID for clients across devices.
- **Repository**: `ClientRepositoryImpl.updateLastClientId()` (`lib/data/repositories/client_repository_impl.dart:111`)

---

### 7. Fetch Doctors
- **Collection**: `doctors`
- **Method**: `.collection('doctors').get()`
- **Purpose**: Retrieves all registered doctor profiles and working days.
- **Repository**: `DoctorRepositoryImpl.getAllDoctors()` (`lib/data/repositories/doctor_repository_impl.dart:36`)

---

### 8. Employee Real-Time HR Updates
- **Collection**: `employees`
- **Method**: `.collection('employees').snapshots()`
- **Purpose**: Real-time broadcast stream for HR dashboard, attendance logs, and leave requests.
- **Service**: `EmployeeService.employeesStream()` (`lib/hr_system/ui/employee_service.dart:60`)

---

### 9. System Services & Feature Requests
- **Collection**: `system_services`
- **Method**: `.collection('system_services').add(requestMap)`
- **Purpose**: Allows clinic admin to request custom feature developments from Zyverse.
- **Screen**: `SystemServicesPage` (`lib/ui/billPaymentScreen/ui/system_services_page.dart`)
