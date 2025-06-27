// lib/ui/LoginPage/models/user_model.dart
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String username;
  final String? role;

  const UserModel({
    required this.id,
    required this.username,
    this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] as String,
      username: data['username'] as String,
      role: data['role'] as String?,
    );
  }

 Map<String, dynamic> toMap() {
    return {
      'username': username,
      'role': role,
      'id': id,
      // Include other fields here
    };
  }
  @override
  List<Object?> get props => [id, username, role];
}
