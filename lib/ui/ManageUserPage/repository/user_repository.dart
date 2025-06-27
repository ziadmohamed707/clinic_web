// lib/ui/ManageUserPage/repository/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class UserRepository {
  final Box _usersBox;
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore, Box? usersBox})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _usersBox = usersBox ?? Hive.box('users');

  // Fetches users from Firestore and updates the local Hive box.
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      // Simple query to check permissions and data retrieval
      final QuerySnapshot snapshot = await _firestore.collection('users')
          //.where('role', isEqualTo: 'admin') // Example query (remove or adjust as needed)
          .get();

      final List<Map<String, dynamic>> users = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      print('Fetched ${users.length} users from Firestore'); // Add logging

      // Optionally, update Hive with the latest data from Firestore
      await _usersBox.clear(); // Clear existing data
      for (var user in users) {
        await _usersBox.put(user['id'], user);
      }

      return users;
    } catch (e) {
      print('Error fetching users from Firestore: $e'); // Log the error
      // Fallback to local Hive data if Firestore fetch fails
      final usersData = _usersBox.values.toList();
      return usersData.map((user) => Map<String, dynamic>.from(user as Map)).toList();
    }
  }

  Future<void> addUser(Map<String, dynamic> userData) async {
    final newUserData = {
      ...userData,
      'id': const Uuid().v4(),
    };
    await _usersBox.put(newUserData['id'], newUserData);
    await _saveUserToFirestore(newUserData);
  }

  Future<void> updateUser(Map<String, dynamic> userData) async {
    await _usersBox.put(userData['id'], userData);
    await _saveUserToFirestore(userData);
  }

  Future<void> deleteUser(String userId) async {
    await _usersBox.delete(userId);
    await _firestore.collection('users').doc(userId).delete();
  }

  Future<void> _saveUserToFirestore(Map<String, dynamic> userData) async {
    await _firestore
        .collection('users')
        .doc(userData['id'] as String)
        .set(userData);
    print('User saved to Firestore with ID: ${userData['id']}');
  }
}
