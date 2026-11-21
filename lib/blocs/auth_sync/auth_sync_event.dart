import 'package:equatable/equatable.dart';

abstract class AuthSyncEvent extends Equatable {
  const AuthSyncEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthSyncStatus extends AuthSyncEvent {
  const CheckAuthSyncStatus();
}

class SignInWithGoogleRequested extends AuthSyncEvent {
  const SignInWithGoogleRequested();
}

class SignOutRequested extends AuthSyncEvent {
  const SignOutRequested();
}

class BackupToCloudRequested extends AuthSyncEvent {
  const BackupToCloudRequested();
}

class RestoreFromCloudRequested extends AuthSyncEvent {
  const RestoreFromCloudRequested();
}
