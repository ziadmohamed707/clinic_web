# Testing Strategy & Coverage Documentation

This document describes the test suite structure, existing tests, test gaps, mocking strategy, and recommended testing procedures for **PhysioOne**.

---

## 🧪 Current Test Suite Evaluation

- **Test Directory**: `test/`
- **Existing Test Files**: `test/widget_test.dart` (Basic smoke test rendering `HomePage(user: testUser)`)
- **Current Coverage Estimate**: **~5%**

---

## 🔬 Existing Smoke Test (`test/widget_test.dart`)

```dart
import 'package:physioone/ui/LoginPage/models/user_model.dart';
import 'package:physioone/ui/HomePage/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomePage renders ScheduleGridScreen smoke test', (
    WidgetTester tester,
  ) async {
    final testUser = UserModel(id: '123', username: 'test_user', role: 'admin');
    await tester.pumpWidget(MaterialApp(home: HomePage(user: testUser)));
  });
}
```

---

## 🚨 Recommended Testing Expansion Roadmap

To reach production-grade test coverage, the following test suites should be implemented:

### 1. Domain Use Case Unit Tests (`test/domain/usecases/`)
- `save_appointment_test.dart`: Test package session deduction logic when booking follow-up sessions vs regular appointments.
- `cancel_appointment_test.dart`: Test package session increment logic when cancelling booked sessions.
- `add_client_test.dart`: Test auto-increment ID logic for new clients.

### 2. BLoC Unit Tests (`test/presentation/bloc/`)
- `auth_bloc_test.dart`: Test state transitions (`unauthenticated` -> `loading` -> `authenticated`).
- `schedule_grid_bloc_test.dart`: Test event handling (`LoadSchedule`, `DateSelected`, `SaveAppointmentEvent`).

### 3. Repository Unit Tests (`test/data/repositories/`)
- `appointment_repository_impl_test.dart`: Test Hive cache fallback and Firestore synchronization using `mockito` or `mocktail`.

---

## 🏃 Running Tests

To execute the test suite:

```bash
flutter test
```
