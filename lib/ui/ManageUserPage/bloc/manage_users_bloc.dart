import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physioone/ui/ManageUserPage/bloc/manage_users_event.dart';
import 'package:physioone/ui/ManageUserPage/bloc/manage_users_state.dart';
import 'package:physioone/ui/ManageUserPage/repository/user_repository.dart';

class ManageUsersBloc extends Bloc<ManageUsersEvent, ManageUsersState> {
  final UserRepository _userRepository;

  ManageUsersBloc({required UserRepository userRepository})
    : _userRepository = userRepository,
      super(ManageUsersState.initial()) {
    on<LoadUsers>(_onLoadUsers);
    on<AddUser>(_onAddUser);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
  }

  Future<void> _onLoadUsers(
    LoadUsers event,
    Emitter<ManageUsersState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        currentAction: 'loading_users',
        isProcessing: true,
      ),
    );

    try {
      final users = await _userRepository.getUsers();
      emit(
        ManageUsersState.success(
          users: users,
          message: 'Users loaded successfully',
        ),
      );
    } catch (e) {
      emit(
        ManageUsersState.failure(
          'Failed to load users: ${e.toString()}',
          action: 'load_users',
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      emit(state.clearMessages());
    }
  }

  Future<void> _onAddUser(AddUser event, Emitter<ManageUsersState> emit) async {
    emit(state.copyWith(isProcessing: true, currentAction: 'adding_user'));

    try {
      await _userRepository.addUser(event.userData);
      final users = await _userRepository.getUsers();
      emit(
        ManageUsersState.success(
          users: users,
          message: 'User added successfully',
        ),
      );
    } catch (e) {
      emit(
        ManageUsersState.failure(
          'Failed to add user: ${e.toString()}',
          action: 'add_user',
        ),
      );
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      emit(state.clearMessages());
    }
  }

  Future<void> _onUpdateUser(
    UpdateUser event,
    Emitter<ManageUsersState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true, currentAction: 'updating_user'));

    try {
      await _userRepository.updateUser(event.userData);
      final users = await _userRepository.getUsers();
      emit(
        ManageUsersState.success(
          users: users,
          message: 'User updated successfully',
        ),
      );
    } catch (e) {
      emit(
        ManageUsersState.failure(
          'Failed to update user: ${e.toString()}',
          action: 'update_user',
        ),
      );
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      emit(state.clearMessages());
    }
  }

  Future<void> _onDeleteUser(
    DeleteUser event,
    Emitter<ManageUsersState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true, currentAction: 'deleting_user'));

    try {
      await _userRepository.deleteUser(event.userId);
      final users = await _userRepository.getUsers();
      emit(
        ManageUsersState.success(
          users: users,
          message: 'User deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        ManageUsersState.failure(
          'Failed to delete user: ${e.toString()}',
          action: 'delete_user',
        ),
      );
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      emit(state.clearMessages());
    }
  }
}
