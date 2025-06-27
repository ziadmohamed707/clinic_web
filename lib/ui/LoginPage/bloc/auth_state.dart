// lib/ui/LoginPage/bloc/auth_state.dart
import 'package:clinic_management_system/ui/LoginPage/models/user_model.dart';
import 'package:equatable/equatable.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? userModel;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.userModel,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? userModel,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userModel: userModel ?? this.userModel,
      errorMessage: errorMessage, // Nullable to clear error
    );
  }

  @override
  List<Object?> get props => [status, userModel, errorMessage];

  // Convenience getters
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get isError => status == AuthStatus.error;
}
