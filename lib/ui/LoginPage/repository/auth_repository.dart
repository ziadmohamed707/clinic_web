// lib/ui/LoginPage/repository/auth_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physioprime/ui/LoginPage/models/user_model.dart'; // Import your UserModel
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart'; // Import Hive
import 'package:rxdart/rxdart.dart';

/// A repository class to encapsulate Firestore operations for user authentication.
/// A repository class to encapsulate Firebase Authentication and Firestore operations
/// related to user management.
class AuthRepository {
  final FirebaseFirestore _firestore;
  // late Box _userSessionBox; // Hive box for user session

  final BehaviorSubject<UserModel?> _currentUserController =
      BehaviorSubject<UserModel?>.seeded(null);

  Stream<UserModel?> get currentUserStream => _currentUserController.stream;

  /// Constructor for AuthRepository.
  ///
  /// Takes optional [firebaseAuth] and [firestore] instances for dependency injection,
  /// defaulting to `FirebaseAuth.instance` and `FirebaseFirestore.instance` respectively.
  AuthRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Signs in a user using their username and password from Firestore.
  ///
  /// **SECURITY WARNING:** This method uses plain-text password comparison,
  /// which is highly insecure. Passwords should be hashed.
  Future<UserModel> signIn({
    required String username,
    required String password,
    bool keepLoggedIn = true,
  }) async {
    final querySnapshot =
        await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .where('password', isEqualTo: password)
            .limit(1)
            .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Invalid username or password.');
    }

    final userDoc = querySnapshot.docs.first;
    final userModel = UserModel.fromMap(userDoc.data());
    _currentUserController.add(userModel);
    if (keepLoggedIn) {
      await saveUserSession(userModel); // ← فقط لو اختار المستخدم ذلك
    } else {
      await clearUserSession();
    }
    // Notify listeners of successful login
    return userModel;
  }

  /// Creates a new user in Firestore.
  ///
  /// **SECURITY WARNING:** This method stores passwords in plain text.
  Future<UserModel> signUp({
    required String email,
    required String username,
    required String password,
  }) async {
    final usernameCheck =
        await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();

    if (usernameCheck.docs.isNotEmpty) {
      throw Exception('Username is already taken.');
    }

    final newUserData = {
      'id': const Uuid().v4(),
      'username': username,
      'email': email,
      'password': password, // INSECURE: Should be hashed
      'role': 'desk', // Default role for new users
    };

    await _firestore
        .collection('users')
        .doc(newUserData['id'])
        .set(newUserData);
    final userModel = UserModel.fromMap(newUserData);
    _currentUserController.add(
      userModel,
    ); // Notify listeners of successful registration
    return userModel;
  }

  /// Signs out the currently authenticated user.
  Future<void> signOut() async {
    try {
      await clearUserSession(); // Clear local session in Hive
      _currentUserController.add(
        null,
      ); // Notify listeners that user is logged out
      print('User session cleared from Hive.');
    } catch (e) {
      throw Exception('Failed to sign out from local session: $e');
    }
  }

  /// Saves the logged-in user's data to local storage (Hive).
  Future<void> saveUserSession(UserModel user) async {
    await Hive.box('userSession').put('currentUser', user.toMap());
  }

  /// Retrieves the logged-in user's data from local storage (Hive).
  UserModel? getUserSession() {
    final userData = Hive.box('userSession').get('currentUser');
    if (userData != null && userData is Map<dynamic, dynamic>) {
      return UserModel.fromMap(Map<String, dynamic>.from(userData));
    }
    return null;
  }

  /// Clears the logged-in user's data from local storage (Hive).
  Future<void> clearUserSession() async {
    await Hive.box('userSession').delete('currentUser');
  }

  /// --- Firestore User Data Management ---

  /// Saves or updates a [UserModel] document in Firestore.
  Future<void> saveUserData(String uid, UserModel userModel) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set(
            userModel.toMap(),
            SetOptions(
              merge: true,
            ), // Use merge to update fields, not overwrite
          );
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  /// Fetches a single [UserModel] document from Firestore by [uid].
  Future<UserModel?> getUserData(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return UserModel.fromMap(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      print("Error fetching user data from Firestore: $e"); // Log the error
      return null; // Return null on error as well
    }
  }

  /// Provides a real-time stream of a [UserModel] document from Firestore by [uid].
  /// This is for live updates to a user's profile data in the database.
  Stream<UserModel?> streamUserData(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return UserModel.fromMap(snapshot.data()!);
          }
          return null;
        })
        .handleError((e) {
          print("Error streaming user data from Firestore: $e");
          return null;
        });
  }

  /// Closes the internal BehaviorSubject when the repository is no longer needed.
  void dispose() {
    _currentUserController.close();
  }

  /// Initializes app-specific data, such as Hive.
  Future<void> initializeAppData() async {
    final userData = Hive.box('userSession').get('currentUser');
    if (userData != null && userData is Map<dynamic, dynamic>) {
      final user = UserModel.fromMap(Map<String, dynamic>.from(userData));
      _currentUserController.add(user);
      print('Session loaded from Hive: ${user.username}');
    } else {
      print('No saved session found.');
    }
  }
}

































// // lib/ui/LoginPage/repository/auth_repository.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:hive/hive.dart';
// import 'package:physioprime/helper/initialize_hive.dart'; // Assuming this helper exists

// class AuthRepository {
//   final FirebaseAuth _firebaseAuth;


//   AuthRepository({FirebaseAuth? firebaseAuth})
//       : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

//   Future<UserCredential> signIn(String email, String password) async {
//     return await _firebaseAuth.signInWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//   }

//   Future<UserCredential> signUp(String email, String password) async {
//     return await _firebaseAuth.createUserWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//   }

//   Future<void> signOut() async {
//     await _firebaseAuth.signOut();
//   }

//   // This method is specific to your app's setup, might be better placed elsewhere
//   // or called directly from the BLoC after successful auth.
//   Future<void> initializeAppData() async {
//     await initializeHive();
//   }
// }
