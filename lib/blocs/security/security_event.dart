import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

abstract class SecurityEvent extends Equatable {
  const SecurityEvent();

  @override
  List<Object?> get props => [];
}

class CheckSecurityStatus extends SecurityEvent {
  const CheckSecurityStatus();
}

class ToggleAppLock extends SecurityEvent {
  final bool enable;
  const ToggleAppLock(this.enable);

  @override
  List<Object?> get props => [enable];
}

class AuthenticateVault extends SecurityEvent {
  const AuthenticateVault();
}

class AppLifecycleChanged extends SecurityEvent {
  final AppLifecycleState state;
  const AppLifecycleChanged(this.state);

  @override
  List<Object?> get props => [state];
}
