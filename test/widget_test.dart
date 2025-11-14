// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:physioone/ui/LoginPage/models/user_model.dart';
import 'package:physioone/ui/HomePage/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomePage renders ScheduleGridScreen smoke test', (
    WidgetTester tester,
  ) async {
    // Create a dummy user for the test.
    final testUser = UserModel(id: '123', username: 'test_user', role: 'admin');
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: HomePage(user: testUser)));
  });
}
