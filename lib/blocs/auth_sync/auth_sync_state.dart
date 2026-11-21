import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthSyncState extends Equatable {
  final User? user;
  final bool isAuthenticating;
  final bool isSyncing;
  final bool isRestoring;
  final DateTime? lastSyncedAt;
  final String? statusMessage;
  final String? errorMessage;

  const AuthSyncState({
    this.user,
    this.isAuthenticating = false,
    this.isSyncing = false,
    this.isRestoring = false,
    this.lastSyncedAt,
    this.statusMessage,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;
  bool get isBusy => isAuthenticating || isSyncing || isRestoring;

  AuthSyncState copyWith({
    User? user,
    bool? clearUser,
    bool? isAuthenticating,
    bool? isSyncing,
    bool? isRestoring,
    DateTime? lastSyncedAt,
    String? statusMessage,
    bool? clearStatusMessage,
    String? errorMessage,
    bool? clearErrorMessage,
  }) {
    return AuthSyncState(
      user: clearUser == true ? null : (user ?? this.user),
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      isSyncing: isSyncing ?? this.isSyncing,
      isRestoring: isRestoring ?? this.isRestoring,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      statusMessage: clearStatusMessage == true
          ? null
          : (statusMessage ?? this.statusMessage),
      errorMessage:
          clearErrorMessage == true ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        user,
        isAuthenticating,
        isSyncing,
        isRestoring,
        lastSyncedAt,
        statusMessage,
        errorMessage,
      ];
}
