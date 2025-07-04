// lib/ui/LoginPage/bloc/auth_event.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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
  final BuildContext? context; // Optional context for navigation

  const LoginSubmitted(
      {required this.username, required this.password, required this.keepLoggedIn, this.context});

  @override
  List<Object> get props => [username, password, keepLoggedIn , context ?? ''];
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

class LogoutRequested extends AuthEvent {
}

