# State Management Documentation

This document describes the state management architecture in **PhysioOne**, detailing BLoC implementations, events, states, stream subscriptions, and reactive controllers.

---

## ⚙️ State Management Overview

PhysioOne relies on `flutter_bloc` (`^9.1.1`), `bloc` (`^9.0.0`), and `rxdart` (`^0.28.0`) for primary application state, complemented by `StatefulWidget` local state for specific UI components.

---

## 🔄 BLoC Modules Detail

### 1. `AuthBloc` (`lib/ui/LoginPage/bloc/auth_bloc.dart`)
- **Responsibility**: Manages authentication lifecycle, startup session checks, login form submissions, and logout requests.
- **Events (`AuthEvent`)**:
  - `AuthStartupCheckRequested`: Triggered on BLoC instantiation to check existing session in Hive.
  - `LoginSubmitted(username, password)`: Submits credentials to `AuthRepository`.
  - `LogoutRequested`: Clears session from Hive and updates state to unauthenticated.
- **States (`AuthState`)**:
  - `AuthStatus`: `unauthenticated`, `loading`, `authenticated`, `error`
  - Properties: `userModel` (contains authenticated `UserModel`), `errorMessage`
- **Stream Subscriptions**: Subscribes to `AuthRepository.currentUserStream` (`BehaviorSubject<UserModel?>`) to automatically react to session changes.

---

### 2. `ScheduleGridBloc` (`lib/ui/ScheduleGridPade/bloc/schedule_grid_bloc.dart`)
- **Responsibility**: Fetches, filters, and manages appointments, available doctors, clients, and summary counts for the main schedule grid.
- **Events (`ScheduleGridEvent`)**:
  - `LoadSchedule(date)`: Loads appointments & doctors for specified date.
  - `DateSelected(newDate)`: Switches selected date and updates grid view.
  - `SyncData`: Re-queries local storage and remote data sources.
  - `SaveAppointmentEvent(appointment, selectedClient, serviceType)`: Invokes `SaveAppointment` usecase.
  - `CancelAppointmentEvent(...)`: Invokes `CancelAppointment` usecase.
  - `AddClientEvent(...)`: Invokes `AddClient` usecase.
- **States (`ScheduleGridState`)**:
  - `ScheduleGridInitial`: Initial empty state.
  - `ScheduleGridLoading`: Processing state.
  - `ScheduleGridLoaded`: Main active state containing:
    - `selectedDate`: DateTime
    - `availableDoctors`: List of doctors available on selected weekday
    - `appointments`: `Map<String, Appointment>` keyed by `appointmentId`
    - `allClients`: List of all clients
    - `todayAppointmentsCount`, `cancelledAppointmentsCount`, `availableSlotsCount`, `totalClientsCount`
    - `successMessage` & `errorMessage`

---

### 3. `ManageUsersBloc` (`lib/ui/ManageUserPage/bloc/manage_users_bloc.dart`)
- **Responsibility**: Handles administrative management of system users and staff accounts.
- **Events**: `LoadUsers`, `AddUser`, `UpdateUser`, `DeleteUser`.
- **States**: `ManageUsersInitial`, `ManageUsersLoading`, `ManageUsersLoaded`, `ManageUsersError`.

---

## 🌊 Stream Controllers & RxDart Usage

- **`AuthRepository.currentUserStream`**: A `BehaviorSubject<UserModel?>` seeded with `null`. When `signIn()` or `signOut()` is invoked, the subject broadcasts changes across the widget tree.
- **Firestore Snapshots**: `HRScreen` and `ScheduleGridScreen` utilize real-time `StreamSubscription` listeners (`.snapshots()`) on Firestore collections (`employees`, `appointments`, `clients`) for live updates.
