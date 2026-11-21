import 'package:equatable/equatable.dart';

class SecurityState extends Equatable {
  final bool isAppLockEnabled;
  final bool isUnlocked;
  final bool isAuthenticating;
  final bool isShieldActive;
  final bool isDeviceSupported;
  final String? errorMessage;

  const SecurityState({
    this.isAppLockEnabled = false,
    this.isUnlocked = true,
    this.isAuthenticating = false,
    this.isShieldActive = false,
    this.isDeviceSupported = false,
    this.errorMessage,
  });

  bool get shouldShowLockScreen => isAppLockEnabled && !isUnlocked;

  SecurityState copyWith({
    bool? isAppLockEnabled,
    bool? isUnlocked,
    bool? isAuthenticating,
    bool? isShieldActive,
    bool? isDeviceSupported,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SecurityState(
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      isShieldActive: isShieldActive ?? this.isShieldActive,
      isDeviceSupported: isDeviceSupported ?? this.isDeviceSupported,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        isAppLockEnabled,
        isUnlocked,
        isAuthenticating,
        isShieldActive,
        isDeviceSupported,
        errorMessage,
      ];
}
