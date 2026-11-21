import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/blocs/security/security_bloc.dart';
import 'package:folio/blocs/security/security_event.dart';
import 'package:folio/blocs/security/security_state.dart';
import 'package:folio/services/security_service.dart';

class _FakeSecurityService extends SecurityService {
  final bool _supported = true;
  bool _appLock = false;
  final bool _authSuccess = true;

  @override
  Future<bool> isBiometricsSupported() async => _supported;

  @override
  Future<bool> isAppLockEnabled() async => _appLock;

  @override
  Future<void> setAppLockEnabled(bool enabled) async {
    _appLock = enabled;
  }

  @override
  Future<bool> authenticate({String reason = ''}) async => _authSuccess;
}

void main() {
  group('SecurityBloc Tests', () {
    late _FakeSecurityService service;
    late SecurityBloc bloc;

    setUp(() {
      service = _FakeSecurityService();
      bloc = SecurityBloc(securityService: service);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state has app lock disabled and unlocked by default', () {
      expect(bloc.state.isAppLockEnabled, isFalse);
      expect(bloc.state.isUnlocked, isTrue);
      expect(bloc.state.isShieldActive, isFalse);
    });

    test(
      'checks status and enables vault protection when configured',
      () async {
        service._appLock = true;
        bloc.add(const CheckSecurityStatus());

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<SecurityState>()
                .having((s) => s.isAppLockEnabled, 'isAppLockEnabled', isTrue)
                .having((s) => s.isUnlocked, 'isUnlocked', isFalse),
            isA<SecurityState>().having(
              (s) => s.isAuthenticating,
              'isAuthenticating',
              isTrue,
            ),
            isA<SecurityState>().having(
              (s) => s.isUnlocked,
              'isUnlocked',
              isTrue,
            ),
          ]),
        );
      },
    );

    test('activates privacy shield when app is sent to background', () async {
      service._appLock = true;
      bloc.add(const CheckSecurityStatus());
      await bloc.stream.firstWhere((s) => s.isUnlocked);

      bloc.add(const AppLifecycleChanged(AppLifecycleState.paused));

      await expectLater(
        bloc.stream,
        emits(
          isA<SecurityState>()
              .having((s) => s.isShieldActive, 'isShieldActive', isTrue)
              .having((s) => s.isUnlocked, 'isUnlocked', isFalse),
        ),
      );
    });

    test('toggles app lock successfully with biometric verification', () async {
      bloc.add(const ToggleAppLock(true));

      await expectLater(
        bloc.stream,
        emits(
          isA<SecurityState>().having(
            (s) => s.isAppLockEnabled,
            'isAppLockEnabled',
            isTrue,
          ),
        ),
      );
    });
  });
}
