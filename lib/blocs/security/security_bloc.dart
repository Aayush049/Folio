import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/security_service.dart';
import 'security_event.dart';
import 'security_state.dart';

class SecurityBloc extends Bloc<SecurityEvent, SecurityState> {
  final SecurityService _securityService;

  SecurityBloc({required SecurityService securityService})
    : _securityService = securityService,
      super(const SecurityState()) {
    on<CheckSecurityStatus>(_onCheckStatus);
    on<ToggleAppLock>(_onToggleAppLock);
    on<AuthenticateVault>(_onAuthenticateVault);
    on<AppLifecycleChanged>(_onLifecycleChanged);
  }

  Future<void> _onCheckStatus(
    CheckSecurityStatus event,
    Emitter<SecurityState> emit,
  ) async {
    final isSupported = await _securityService.isBiometricsSupported();
    final isEnabled = await _securityService.isAppLockEnabled();

    emit(
      state.copyWith(
        isDeviceSupported: isSupported,
        isAppLockEnabled: isEnabled,
        isUnlocked: !isEnabled,
      ),
    );

    if (isEnabled) {
      add(const AuthenticateVault());
    }
  }

  Future<void> _onToggleAppLock(
    ToggleAppLock event,
    Emitter<SecurityState> emit,
  ) async {
    if (event.enable) {
      // Must verify biometric auth before enabling lock
      final success = await _securityService.authenticate(
        reason: 'Authenticate to enable Folio Vault Lock',
      );
      if (success) {
        await _securityService.setAppLockEnabled(true);
        emit(
          state.copyWith(
            isAppLockEnabled: true,
            isUnlocked: true,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            errorMessage: 'Authentication failed. Vault lock was not enabled.',
          ),
        );
      }
    } else {
      // Verify before disabling
      final success = await _securityService.authenticate(
        reason: 'Authenticate to turn off Folio Vault Lock',
      );
      if (success) {
        await _securityService.setAppLockEnabled(false);
        emit(
          state.copyWith(
            isAppLockEnabled: false,
            isUnlocked: true,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            errorMessage: 'Authentication failed. Vault lock remains enabled.',
          ),
        );
      }
    }
  }

  Future<void> _onAuthenticateVault(
    AuthenticateVault event,
    Emitter<SecurityState> emit,
  ) async {
    if (!state.isAppLockEnabled) {
      emit(state.copyWith(isUnlocked: true));
      return;
    }

    emit(state.copyWith(isAuthenticating: true, clearError: true));
    final authenticated = await _securityService.authenticate(
      reason: 'Scan fingerprint or Face ID to unlock your documents',
    );

    emit(
      state.copyWith(
        isAuthenticating: false,
        isUnlocked: authenticated,
        errorMessage: authenticated
            ? null
            : 'Authentication required to access documents.',
      ),
    );
  }

  void _onLifecycleChanged(
    AppLifecycleChanged event,
    Emitter<SecurityState> emit,
  ) {
    if (!state.isAppLockEnabled) return;

    if (event.state == AppLifecycleState.inactive ||
        event.state == AppLifecycleState.paused) {
      // Activate task switcher privacy shield & lock vault
      emit(state.copyWith(isShieldActive: true, isUnlocked: false));
    } else if (event.state == AppLifecycleState.resumed) {
      // Deactivate shield when returning and prompt for auth
      emit(state.copyWith(isShieldActive: false));
      add(const AuthenticateVault());
    }
  }
}
