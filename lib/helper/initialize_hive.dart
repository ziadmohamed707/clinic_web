import 'package:physioprime/utils/hive_adapters.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> initializeHive() async {
  try {
    await Hive.initFlutter();
    await Hive.openBox('appointments');
    await Hive.openBox('clients');
    await Hive.openBox('doctors'); // Add new box for doctors
    await Hive.openBox('users'); // Add this line to open the 'users' box
    await Hive.openBox('userSession'); // Ensure userSession box is opened here
    Hive.registerAdapter(TimestampAdapter()); // Register the TimestampAdapter

    if (!Hive.box('clients').containsKey('lastId')) {
      Hive.box('clients').put('lastId', 0);
    }
  } catch (e) {
    // Professional Error Handling: Log and potentially show a user-friendly message.
    print('Error initializing Hive: $e');
    // In a real app, you might want to show a persistent error screen or dialog.
  }
}
// lib/helper/local_storage_service.dart (or merged into initialize_hive.dart)
// For @required and debugPrint

const String _userBoxName = 'userBox';
const String _loggedInUserIdKey = 'loggedInUserId';

Future<void> initializeLocalStorage() async {
  // Ensure Hive is initialized globally (e.g., in main.dart) before calling this.
  // This function just ensures the specific box is open.
  if (!Hive.isBoxOpen(_userBoxName)) {
    await Hive.openBox<String>(_userBoxName);
    debugPrint('$_userBoxName box opened.');
  }
}

/// Stores the user ID in local storage to indicate a logged-in session.
Future<void> setLoggedInUserId(String userId) async {
  final box = await Hive.openBox<String>(_userBoxName);
  await box.put(_loggedInUserIdKey, userId);
  debugPrint('User ID $userId saved to Hive.');
}

/// Retrieves the logged-in user ID from local storage.
/// Returns null if no user is logged in.
Future<String?> getLoggedInUserId() async {
  final box = await Hive.openBox<String>(_userBoxName);
  final userId = box.get(_loggedInUserIdKey);
  debugPrint('Retrieved user ID from Hive: $userId');
  return userId;
}

/// Clears the logged-in user ID from local storage, effectively logging out.
Future<void> clearLoggedInUserId() async {
  final box = await Hive.openBox<String>(_userBoxName);
  await box.delete(_loggedInUserIdKey);
  debugPrint('User ID cleared from Hive (logged out).');
}
