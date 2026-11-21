import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import 'auth_sync_event.dart';
import 'auth_sync_state.dart';

class AuthSyncBloc extends Bloc<AuthSyncEvent, AuthSyncState> {
  final AuthService _authService;
  final SyncService _syncService;
  StreamSubscription? _authSub;

  AuthSyncBloc({
    required AuthService authService,
    required SyncService syncService,
  }) : _authService = authService,
       _syncService = syncService,
       super(AuthSyncState(user: authService.currentUser)) {
    on<CheckAuthSyncStatus>(_onCheckStatus);
    on<SignInWithGoogleRequested>(_onSignInWithGoogle);
    on<SignOutRequested>(_onSignOut);
    on<BackupToCloudRequested>(_onBackupToCloud);
    on<RestoreFromCloudRequested>(_onRestoreFromCloud);

    _authSub = _authService.authStateChanges.listen((user) {
      add(const CheckAuthSyncStatus());
    });
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }

  Future<void> _onCheckStatus(
    CheckAuthSyncStatus event,
    Emitter<AuthSyncState> emit,
  ) async {
    final user = _authService.currentUser;
    DateTime? lastSync;
    if (user != null) {
      lastSync = await _syncService.getLastSyncTime();
    }
    emit(
      state.copyWith(
        user: user,
        clearUser: user == null,
        lastSyncedAt: lastSync,
      ),
    );
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleRequested event,
    Emitter<AuthSyncState> emit,
  ) async {
    emit(
      state.copyWith(
        isAuthenticating: true,
        clearErrorMessage: true,
        clearStatusMessage: true,
      ),
    );
    try {
      final user = await _authService.signInWithGoogle();
      DateTime? lastSync;
      if (user != null) {
        lastSync = await _syncService.getLastSyncTime();
      }
      emit(
        state.copyWith(
          user: user,
          clearUser: user == null,
          isAuthenticating: false,
          lastSyncedAt: lastSync,
          statusMessage: user != null
              ? 'Signed in as ${user.displayName ?? user.email}'
              : null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isAuthenticating: false,
          errorMessage: 'Sign in failed: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthSyncState> emit,
  ) async {
    emit(
      state.copyWith(
        isAuthenticating: true,
        clearErrorMessage: true,
        clearStatusMessage: true,
      ),
    );
    try {
      await _authService.signOut();
      emit(const AuthSyncState(statusMessage: 'Signed out successfully.'));
    } catch (e) {
      emit(
        state.copyWith(
          isAuthenticating: false,
          errorMessage: 'Sign out failed: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onBackupToCloud(
    BackupToCloudRequested event,
    Emitter<AuthSyncState> emit,
  ) async {
    if (state.user == null) {
      emit(state.copyWith(errorMessage: 'Please sign in to back up data.'));
      return;
    }
    emit(
      state.copyWith(
        isSyncing: true,
        clearErrorMessage: true,
        clearStatusMessage: true,
      ),
    );
    try {
      final result = await _syncService.backupAllToCloud();
      emit(
        state.copyWith(
          isSyncing: false,
          lastSyncedAt: result.timestamp,
          statusMessage: result.message,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSyncing: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onRestoreFromCloud(
    RestoreFromCloudRequested event,
    Emitter<AuthSyncState> emit,
  ) async {
    if (state.user == null) {
      emit(state.copyWith(errorMessage: 'Please sign in to restore data.'));
      return;
    }
    emit(
      state.copyWith(
        isRestoring: true,
        clearErrorMessage: true,
        clearStatusMessage: true,
      ),
    );
    try {
      final result = await _syncService.restoreAllFromCloud();
      emit(
        state.copyWith(
          isRestoring: false,
          lastSyncedAt: result.timestamp,
          statusMessage: result.message,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isRestoring: false, errorMessage: e.toString()));
    }
  }
}
