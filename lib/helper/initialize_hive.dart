import 'package:physioprime/utils/hive_adapters.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Track if Hive has been initialized to prevent multiple initializations
bool _isHiveInitialized = false;

Future<void> initializeHive() async {
  // Prevent multiple initializations
  if (_isHiveInitialized) {
    print('Hive already initialized, skipping...');
    return;
  }

  try {
    await Hive.initFlutter();
    
    // Register adapters only if they haven't been registered yet
    // TimestampAdapter uses typeId 50 (changed to avoid conflicts)
    if (!Hive.isAdapterRegistered(50)) {
      Hive.registerAdapter(TimestampAdapter());
      print('TimestampAdapter registered successfully');
    } else {
      print('TimestampAdapter (typeId: 50) already registered');
    }
    
    // Register other adapters if you have them
    // Example:
    // if (!Hive.isAdapterRegistered(100)) {
    //   Hive.registerAdapter(UserModelAdapter());
    //   print('UserModelAdapter registered successfully');
    // }
    
    // if (!Hive.isAdapterRegistered(101)) {
    //   Hive.registerAdapter(AppointmentModelAdapter());
    //   print('AppointmentModelAdapter registered successfully');
    // }
    
    // Open boxes safely
    await _openBoxSafely('appointments');
    await _openBoxSafely('clients');
    await _openBoxSafely('doctors');
    await _openBoxSafely('users');
    await _openBoxSafely('userSession');
    await _openBoxSafely('userBox'); // For the local storage service
    
    // Initialize default values
    final clientsBox = Hive.box('clients');
    if (!clientsBox.containsKey('lastId')) {
      await clientsBox.put('lastId', 0);
    }
    
    _isHiveInitialized = true;
    print('Hive initialized successfully');
    
  } catch (e) {
    print('Error initializing Hive: $e');
    // Reset flag on error so we can try again
    _isHiveInitialized = false;
    rethrow;
  }
}

/// Helper method to safely open boxes
Future<void> _openBoxSafely(String boxName) async {
  try {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
      print('Got object store box in database $boxName.');
    } else {
      print('Box $boxName is already open.');
    }
  } catch (e) {
    print('Error opening box $boxName: $e');
    // Try to delete corrupted box and recreate
    try {
      await Hive.deleteBoxFromDisk(boxName);
      await Hive.openBox(boxName);
      print('Recreated corrupted box: $boxName');
    } catch (deleteError) {
      print('Failed to recreate box $boxName: $deleteError');
      rethrow;
    }
  }
}

// ============================================================================
// LOCAL STORAGE SERVICE
// ============================================================================

const String _userBoxName = 'userBox';
const String _loggedInUserIdKey = 'loggedInUserId';

Future<void> initializeLocalStorage() async {
  // Ensure main Hive initialization is done first
  if (!_isHiveInitialized) {
    await initializeHive();
  }
  
  // The box should already be open from initializeHive(), but check anyway
  if (!Hive.isBoxOpen(_userBoxName)) {
    await Hive.openBox<String>(_userBoxName);
    debugPrint('$_userBoxName box opened.');
  }
}

/// Stores the user ID in local storage to indicate a logged-in session.
Future<void> setLoggedInUserId(String userId) async {
  try {
    await initializeLocalStorage(); // Ensure box is open
    final box = Hive.box<String>(_userBoxName);
    await box.put(_loggedInUserIdKey, userId);
    debugPrint('User ID $userId saved to Hive.');
  } catch (e) {
    debugPrint('Error saving user ID to Hive: $e');
    rethrow;
  }
}

/// Retrieves the logged-in user ID from local storage.
/// Returns null if no user is logged in.
Future<String?> getLoggedInUserId() async {
  try {
    await initializeLocalStorage(); // Ensure box is open
    final box = Hive.box<String>(_userBoxName);
    final userId = box.get(_loggedInUserIdKey);
    debugPrint('Retrieved user ID from Hive: $userId');
    return userId;
  } catch (e) {
    debugPrint('Error retrieving user ID from Hive: $e');
    return null;
  }
}

/// Clears the logged-in user ID from local storage, effectively logging out.
Future<void> clearLoggedInUserId() async {
  try {
    await initializeLocalStorage(); // Ensure box is open
    final box = Hive.box<String>(_userBoxName);
    await box.delete(_loggedInUserIdKey);
    debugPrint('User ID cleared from Hive (logged out).');
  } catch (e) {
    debugPrint('Error clearing user ID from Hive: $e');
    rethrow;
  }
}

/// Clean up method to close all boxes when app is disposed
Future<void> closeHive() async {
  try {
    await Hive.close();
    _isHiveInitialized = false;
    print('All Hive boxes closed');
  } catch (e) {
    print('Error closing Hive: $e');
  }
}

/// Development/debugging method to clear all Hive data
Future<void> clearAllHiveData() async {
  try {
    await Hive.deleteFromDisk();
    _isHiveInitialized = false;
    print('All Hive data cleared');
  } catch (e) {
    print('Error clearing Hive data: $e');
  }
}