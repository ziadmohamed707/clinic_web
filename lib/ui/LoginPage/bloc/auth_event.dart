// lib/ui/LoginPage/bloc/auth_event.dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}
class AuthStartupCheckRequested extends AuthEvent {}
class LoginSubmitted extends AuthEvent {
  final String username;
  final String password;
  final bool keepLoggedIn;

  const LoginSubmitted(
      {required this.username, required this.password, required this.keepLoggedIn});

  @override
  List<Object> get props => [username, password, keepLoggedIn];
}

class RegisterSubmitted extends AuthEvent {
  final String email;
  final String username;
  final String password;
  final bool keepLoggedIn;

  const RegisterSubmitted(
      {required this.email, required this.username, required this.password, required this.keepLoggedIn});

  @override
  List<Object> get props => [email, username, password, keepLoggedIn];
}

class LogoutRequested extends AuthEvent {}
