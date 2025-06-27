// lib/ui/LoginPage/bloc/auth_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:clinic_management_system/ui/LoginPage/bloc/auth_event.dart';
import 'package:clinic_management_system/ui/LoginPage/bloc/auth_state.dart';
import 'package:clinic_management_system/ui/LoginPage/models/user_model.dart';
import 'package:clinic_management_system/ui/LoginPage/repository/auth_repository.dart';
import 'dart:async'; // Import for StreamSubscription

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  late StreamSubscription<UserModel?>
  _userSessionSubscription; // Declare a subscription

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthState(status: AuthStatus.unauthenticated)) {
    // 1. Initial State Handling:
    // DON'T call async methods directly in the constructor like _loadUserSession().
    // Instead, dispatch an event that will handle loading the session.
    on<AuthStartupCheckRequested>(_onAuthStartupCheckRequested);
    // 2. Continuous Session Monitoring:
    // Subscribe to the repository's user session stream to react to changes (login/logout)
    _userSessionSubscription = _authRepository.currentUserStream.listen(
      (userModel) {
        // When the stream emits a user, it means they are authenticated.
        // When it emits null, they are unauthenticated.
        if (userModel != null) {
          emit(
            state.copyWith(
              status: AuthStatus.authenticated,
              userModel: userModel,
              errorMessage: null,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: AuthStatus.unauthenticated,
              userModel: null,
              errorMessage: null,
            ),
          );
        }
      },
      onError: (error) {
        // Handle stream errors, e.g., issues with Hive or unexpected data.
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: "Session stream error: ${error.toString()}",
          ),
        );
      },
    );

    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<LogoutRequested>(_onLogoutRequested);

    // After setting up all event handlers, dispatch the initial check event.
    add(AuthStartupCheckRequested());
  }

  // --- New Event Handler for Initial Startup Check ---
  Future<void> _onAuthStartupCheckRequested(
    AuthStartupCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // This event handler will be triggered once on BLoC creation.
    // The actual state update is handled by the _userSessionSubscription listener.
    // We just need to ensure the AuthRepository has had a chance to initialize its
    // currentUserStream by loading from Hive. The initializeAppData() handles this.
    try {
      // Ensure app data (Hive) is initialized before trying to get session
      // This call should be safe to run multiple times, or idempotent, if already initialized.
      await _authRepository.initializeAppData();
      // The listener `_userSessionSubscription` will now pick up the initial
      // user session loaded by `initializeAppData` and emit the correct state.
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage:
              "Failed to initialize app data on startup: ${e.toString()}",
        ),
      );
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    // Always emit loading first. The _userSessionSubscription will then update to authenticated/unauthenticated.
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      // The `signIn` method now updates `_authRepository.currentUserStream` directly.
      await _authRepository.signIn(
        username: event.username,
        password: event.password,
      );
      // The `_authRepository.signIn` method already calls `saveUserSession`
      // and adds the `userModel` to `_authRepository.currentUserStream`.
      // Thus, `_userSessionSubscription` (which we set up in the constructor)
      // will pick up this change and emit the `AuthStatus.authenticated` state.
      // So, we don't need to emit state directly here.

      // Removed redundant initializeAppData() here as it should be called once on startup.
      // The keepLoggedIn logic is now implicitly handled by the repository's saveUserSession
      // which is called inside signIn, and this is fine because we want
      // the session saved regardless of a "keepLoggedIn" flag if login succeeds
      // for the current session. If "keepLoggedIn" means *persistent* storage beyond app restart,
      // then `saveUserSession` is doing that. If it means *only* persist if checked,
      // then you'd move saveUserSession inside the if(event.keepLoggedIn) block in repository.
      // Given your repository's signIn method already calls saveUserSession,
      // the `event.keepLoggedIn` implies whether to *continue* persisting for future runs.
      // For a Firestore-only + Hive model, `saveUserSession` usually handles persistence.
      if (!event.keepLoggedIn) {
        await _authRepository.clearUserSession();
      }
    } catch (e) {
      // Only emit error state if the login operation itself fails
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final userModel = await _authRepository.signUp(
        email: event.email,
        username: event.username,
        password: event.password,
      );
      // The `_authRepository.signUp` method already calls `saveUserSession`
      // and adds the `userModel` to `_authRepository.currentUserStream`.
      // Thus, `_userSessionSubscription` will pick up this change and emit the authenticated state.
      // No explicit emit here.

      // Removed redundant initializeAppData() here.
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(status: AuthStatus.loading, errorMessage: null),
    ); // Optional: Show loading during logout
    try {
      await _authRepository.signOut();
      // The `_authRepository.signOut` method already calls `clearUserSession`
      // and adds `null` to `_authRepository.currentUserStream`.
      // Thus, `_userSessionSubscription` will pick up this change and emit the `AuthStatus.unauthenticated` state.
      // No explicit emit here.

      // Removed redundant await _authRepository.clearUserSession();
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _userSessionSubscription.cancel(); // Cancel the subscription
    _authRepository
        .dispose(); // Call dispose on your repository's stream controller
    return super.close();
  }
}
