// lib/ui/LoginPage/repository/auth_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:physioone/ui/LoginPage/models/user_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final FirebaseFirestore _firestore;
  static const String _userSessionBoxName = 'userSession';
  static const String _currentUserKey = 'currentUser';

  final BehaviorSubject<UserModel?> _currentUserController =
      BehaviorSubject<UserModel?>.seeded(null);

  Stream<UserModel?> get currentUserStream => _currentUserController.stream;

  AuthRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Signs in a user - NO need to reinitialize Hive
  Future<UserModel> signIn({
    required String username,
    required String password,
    bool keepLoggedIn = true,
  }) async {
    final querySnapshot =
        await _firestore
            .collection('employees') // Step 1: Authenticate against the 'users' collection
            .where('username', isEqualTo: username)
            .where('password', isEqualTo: password)
            .limit(1)
            .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Invalid username or password.');
    }

    final authUserDoc = querySnapshot.docs.first;
    final userId = authUserDoc.id;

    // Step 2: Fetch the full employee profile from the 'employees' collection using the user's ID.
    final employeeDoc =
        await _firestore.collection('employees').doc(userId).get();

    if (!employeeDoc.exists) {
      throw Exception('Employee profile not found for the authenticated user.');
    }
    final userModel = UserModel.fromFirestore(employeeDoc);

    // Update current user stream
    _currentUserController.add(userModel);

    if (keepLoggedIn) {
      await saveUserSession(userModel);
    } else {
      await clearUserSession();
    }

    debugPrint('User signed in: ${userModel.username}');
    return userModel;
  }

  /// Signs out the user - Only clear session, don't reinitialize Hive
  Future<void> signOut() async {
    try {
      // Clear user session from Hive
      await clearUserSession();

      // Clear any other user-specific data if needed
      await _clearUserSpecificData();

      // Update current user stream
      _currentUserController.add(null);

      debugPrint('User signed out successfully');
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Clear user-specific data without reinitializing Hive
  Future<void> _clearUserSpecificData() async {
    try {
      // Clear user-specific boxes or data
      if (Hive.isBoxOpen('userBox')) {
        await Hive.box('userBox').clear();
      }

      // You can clear specific keys instead of entire boxes
      // await Hive.box('someBox').delete('userSpecificKey');
    } catch (e) { 
      debugPrint('Error clearing user-specific data: $e');
    }
  }

  /// Save user session to Hive (box should already be open)
  Future<void> saveUserSession(UserModel user) async {
    try {
      final box = Hive.box(_userSessionBoxName);
      await box.put(_currentUserKey, user.toMap());
      debugPrint('User session saved: ${user.username}');
    } catch (e) {
      debugPrint('Error saving user session: $e');
      throw Exception('Failed to save user session: $e');
    }
  }

  /// Get user session from Hive
  UserModel? getUserSession() {
    try { 
      if (!Hive.isBoxOpen(_userSessionBoxName)) { 
        debugPrint('UserSession box is not open');
        return null;
      }

      final box = Hive.box(_userSessionBoxName);
      final userData = box.get(_currentUserKey);

      if (userData != null && userData is Map<dynamic, dynamic>) {
        final userMap = Map<String, dynamic>.from(userData);
        return UserModel.fromMap(userMap, userMap['docId'] ?? '');
      }
      return null;
    } catch (e) { 
      debugPrint('Error getting user session: $e');
      return null;
    }
  }

  /// Clear user session from Hive
  Future<void> clearUserSession() async {
    try {
      final box = Hive.box(_userSessionBoxName);
      await box.delete(_currentUserKey);
      debugPrint('User session cleared');
    } catch (e) {
      debugPrint('Error clearing user session: $e');
      throw Exception('Failed to clear user session: $e');
    }
  }

  /// Initialize app data (call this once at app startup)
  Future<void> initializeAppData() async {
    try {
      final user = getUserSession();
      if (user != null) {
        _currentUserController.add(user);
        debugPrint('Session loaded from Hive: ${user.username}');
      } else {
        debugPrint('No saved session found.');
      }
    } catch (e) {
      debugPrint('Error initializing app data: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _currentUserController.close();
  }
}


// // lib/ui/LoginPage/repository/auth_repository.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:physioone/ui/LoginPage/models/user_model.dart'; // Import your UserModel
// import 'package:uuid/uuid.dart';
// import 'package:hive/hive.dart'; // Import Hive
// import 'package:rxdart/rxdart.dart';

// /// A repository class to encapsulate Firestore operations for user authentication.
// /// A repository class to encapsulate Firebase Authentication and Firestore operations
// /// related to user management.
// class AuthRepository {
//   final FirebaseFirestore _firestore;
//   // late Box _userSessionBox; // Hive box for user session

//   final BehaviorSubject<UserModel?> _currentUserController =
//       BehaviorSubject<UserModel?>.seeded(null);

//   Stream<UserModel?> get currentUserStream => _currentUserController.stream;

//   /// Constructor for AuthRepository.
//   ///
//   /// Takes optional [firebaseAuth] and [firestore] instances for dependency injection,
//   /// defaulting to `FirebaseAuth.instance` and `FirebaseFirestore.instance` respectively.
//   AuthRepository({FirebaseFirestore? firestore})
//     : _firestore = firestore ?? FirebaseFirestore.instance;

//   /// Signs in a user using their username and password from Firestore.
//   ///
//   /// **SECURITY WARNING:** This method uses plain-text password comparison,
//   /// which is highly insecure. Passwords should be hashed.
//   Future<UserModel> signIn({
//     required String username,
//     required String password,
//     bool keepLoggedIn = true,
//   }) async {
//     final querySnapshot =
//         await _firestore
//             .collection('users')
//             .where('username', isEqualTo: username)
//             .where('password', isEqualTo: password)
//             .limit(1)
//             .get();

//     if (querySnapshot.docs.isEmpty) {
//       throw Exception('Invalid username or password.');
//     }

//     final userDoc = querySnapshot.docs.first;
//     final userModel = UserModel.fromMap(userDoc.data());
//     _currentUserController.add(userModel);
//     if (keepLoggedIn) {
//       await saveUserSession(userModel); // ← فقط لو اختار المستخدم ذلك
//     } else {
//       await clearUserSession(_currentUserController.value!.username);
//     }
//     // Notify listeners of successful login
//     return userModel;
//   }

//   /// Creates a new user in Firestore.
//   ///
//   /// **SECURITY WARNING:** This method stores passwords in plain text.
//   Future<UserModel> signUp({
//     required String email,
//     required String username,
//     required String password,
//   }) async {
//     final usernameCheck =
//         await _firestore
//             .collection('users')
//             .where('username', isEqualTo: username)
//             .limit(1)
//             .get();

//     if (usernameCheck.docs.isNotEmpty) {
//       throw Exception('Username is already taken.');
//     }

//     final newUserData = {
//       'id': const Uuid().v4(),
//       'username': username,
//       'email': email,
//       'password': password, // INSECURE: Should be hashed
//       'role': 'desk', // Default role for new users
//     };

//     await _firestore
//         .collection('users')
//         .doc(newUserData['id'])
//         .set(newUserData);
//     final userModel = UserModel.fromMap(newUserData);
//     _currentUserController.add(
//       userModel,
//     ); // Notify listeners of successful registration
//     return userModel;
//   }

//   /// Signs out the currently authenticated user.
//   Future<void> signOut() async {
//     try {
//       await clearUserSession(
//         _currentUserController.value!.username,
//       ); // Clear local session in Hive
//       _currentUserController.add(
//         null,
//       ); // Notify listeners that user is logged out
//       print('User session cleared from Hive.');
//     } catch (e) {
//       throw Exception('Failed to sign out from local session: $e');
//     }
//   }

//   /// Saves the logged-in user's data to local storage (Hive).
//   Future<void> saveUserSession(UserModel user) async {
//     await Hive.box('userSession').put('currentUser', user.toMap());
//   }

//   /// Retrieves the logged-in user's data from local storage (Hive).
//   UserModel? getUserSession() {
//     final userData = Hive.box('userSession').get('currentUser');
//     if (userData != null && userData is Map<dynamic, dynamic>) {
//       return UserModel.fromMap(Map<String, dynamic>.from(userData));
//     }
//     return null;
//   }

//   /// Clears the logged-in user's data from local storage (Hive).
//   Future<void> clearUserSession(currentUser) async {
//     final box = await Hive.openBox('userSession');
//     await box.delete('currentUser');
//   }

//   /// --- Firestore User Data Management ---

//   /// Saves or updates a [UserModel] document in Firestore.
//   Future<void> saveUserData(String uid, UserModel userModel) async {
//     try {
//       await _firestore
//           .collection('users')
//           .doc(uid)
//           .set(
//             userModel.toMap(),
//             SetOptions(
//               merge: true,
//             ), // Use merge to update fields, not overwrite
//           );
//     } catch (e) {
//       throw Exception('Failed to save user data: $e');
//     }
//   }

//   /// Fetches a single [UserModel] document from Firestore by [uid].
//   Future<UserModel?> getUserData(String uid) async {
//     try {
//       final docSnapshot = await _firestore.collection('users').doc(uid).get();
//       if (docSnapshot.exists && docSnapshot.data() != null) {
//         return UserModel.fromMap(docSnapshot.data()!);
//       }
//       return null;
//     } catch (e) {
//       print("Error fetching user data from Firestore: $e"); // Log the error
//       return null; // Return null on error as well
//     }
//   }

//   /// Provides a real-time stream of a [UserModel] document from Firestore by [uid].
//   /// This is for live updates to a user's profile data in the database.
//   Stream<UserModel?> streamUserData(String uid) {
//     return _firestore
//         .collection('users')
//         .doc(uid)
//         .snapshots()
//         .map((snapshot) {
//           if (snapshot.exists && snapshot.data() != null) {
//             return UserModel.fromMap(snapshot.data()!);
//           }
//           return null;
//         })
//         .handleError((e) {
//           print("Error streaming user data from Firestore: $e");
//           return null;
//         });
//   }

//   /// Closes the internal BehaviorSubject when the repository is no longer needed.
//   void dispose() {
//     _currentUserController.close();
//   }

//   /// Initializes app-specific data, such as Hive.
//   Future<void> initializeAppData() async {
//     final userData = Hive.box('userSession').get('currentUser');
//     if (userData != null && userData is Map<dynamic, dynamic>) {
//       final user = UserModel.fromMap(Map<String, dynamic>.from(userData));
//       _currentUserController.add(user);
//       print('Session loaded from Hive: ${user.username}');
//     } else {
//       print('No saved session found.');
//     }
//   }
// }

































// // // lib/ui/LoginPage/repository/auth_repository.dart
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:hive/hive.dart';
// // import 'package:physioone/helper/initialize_hive.dart'; // Assuming this helper exists

// // class AuthRepository {
// //   final FirebaseAuth _firebaseAuth;


// //   AuthRepository({FirebaseAuth? firebaseAuth})
// //       : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

// //   Future<UserCredential> signIn(String email, String password) async {
// //     return await _firebaseAuth.signInWithEmailAndPassword(
// //       email: email,
// //       password: password,
// //     );
// //   }

// //   Future<UserCredential> signUp(String email, String password) async {
// //     return await _firebaseAuth.createUserWithEmailAndPassword(
// //       email: email,
// //       password: password,
// //     );
// //   }

// //   Future<void> signOut() async {
// //     await _firebaseAuth.signOut();
// //   }

// //   // This method is specific to your app's setup, might be better placed elsewhere
// //   // or called directly from the BLoC after successful auth.
// //   Future<void> initializeAppData() async {
// //     await initializeHive();
// //   }
// // }
