// lib/ui/ManageUserPage/bloc/manage_users_event.dart
import 'package:equatable/equatable.dart';

abstract class ManageUsersEvent extends Equatable {
  const ManageUsersEvent();

  @override
  List<Object> get props => [];
}

class LoadUsers extends ManageUsersEvent {}

class AddUser extends ManageUsersEvent {
  final Map<String, dynamic> userData;

  const AddUser(this.userData);

  @override
  List<Object> get props => [userData];
}

class UpdateUser extends ManageUsersEvent {
  final Map<String, dynamic> userData;

  const UpdateUser(this.userData);

  @override
  List<Object> get props => [userData];
}

class DeleteUser extends ManageUsersEvent {
  final String userId;

  const DeleteUser(this.userId);

  @override
  List<Object> get props => [userId];
}
