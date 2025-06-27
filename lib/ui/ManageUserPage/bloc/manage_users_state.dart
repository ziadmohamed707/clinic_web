// lib/ui/ManageUserPage/bloc/manage_users_state.dart
import 'package:equatable/equatable.dart';

class ManageUsersState extends Equatable {
  final List<Map<String, dynamic>> users;
  final bool isLoading;
  final String? error;

  const ManageUsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  ManageUsersState copyWith({
    List<Map<String, dynamic>>? users,
    bool? isLoading,
    String? error, required String currentAction, required bool isProcessing,
  }) {
    return ManageUsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }


  @override
  List<Object?> get props => [users, isLoading, error];

  get successMessage => null;

  static ManageUsersState initial() {
    return const ManageUsersState(
      users: [],
      isLoading: false,
      error: null,
    );
  }

  static ManageUsersState success({required List<Map<String, dynamic>> users, required String message}) {
    return ManageUsersState(
      users: users,
      isLoading: false,
      error: null,
      
    );
  }

  static ManageUsersState failure(String s, {required String action}) {
    return ManageUsersState(
      users: [],
      isLoading: false,
      error: s,
    );
  }

  ManageUsersState clearMessages() {
    return ManageUsersState(
      users: users,
      isLoading: isLoading,
      error: null,
    );
  }
}
