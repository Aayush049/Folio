import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/security/security_bloc.dart';
import '../../blocs/security/security_event.dart';
import '../../blocs/security/security_state.dart';
import '../../core/folio_theme.dart';
import 'folio_logo.dart';
import 'neu_widgets.dart';

void showVaultSecuritySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _VaultSecuritySettingsSheet(),
  );
}

class VaultLockOverlay extends StatelessWidget {
  final Widget child;

  const VaultLockOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SecurityBloc, SecurityState>(
      builder: (context, state) {
        return Stack(
          children: [
            child,

            // Task switcher privacy shield (when app is in background/inactive)
            if (state.isShieldActive)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.8),
                    alignment: Alignment.center,
                    child: const FolioLogo(size: 64),
                  ),
                ),
              ),

            // Active vault lock screen (when app is launched/resumed and lock is enabled)
            if (state.shouldShowLockScreen && !state.isShieldActive)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: _VaultLockScreen(state: state),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _VaultLockScreen extends StatelessWidget {
  final SecurityState state;

  const _VaultLockScreen({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<FolioThemeNotifier>();

    return Container(
      color: theme.bg,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FolioLogo(size: 72, showShadow: true),
            const SizedBox(height: 28),
            NeuBox(
              borderRadius: 30,
              padding: const EdgeInsets.all(22),
              child: Icon(
                Icons.lock_rounded,
                size: 44,
                color: theme.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Folio Vault Locked',
              style: GoogleFonts.nunito(
                color: theme.text,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Biometric authentication or device PIN is required to access your documents.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: theme.textSub,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 36),
            NeuButton(
              filled: true,
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              onTap: state.isAuthenticating
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      context.read<SecurityBloc>().add(const AuthenticateVault());
                    },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.isAuthenticating)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                    )
                  else
                    const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    state.isAuthenticating ? 'Authenticating...' : 'Unlock Vault',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VaultSecuritySettingsSheet extends StatelessWidget {
  const _VaultSecuritySettingsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<FolioThemeNotifier>();

    return Container(
      constraints: const BoxConstraints(maxWidth: 550),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: theme.raisedShadow,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: BlocConsumer<SecurityBloc, SecurityState>(
            listener: (context, state) {
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage!), backgroundColor: theme.danger),
                );
              }
            },
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.textSub.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.accentSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.security_rounded, color: theme.accent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Security & Privacy Vault',
                              style: GoogleFonts.nunito(
                                color: theme.text,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Biometric lock & privacy shield protection',
                              style: GoogleFonts.nunito(
                                color: theme.textSub,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: theme.textSub),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Toggle Switch Tile
                  NeuBox(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Biometric / PIN Lock',
                                style: GoogleFonts.nunito(
                                  color: theme.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Require fingerprint, Face ID or device PIN on launch',
                                style: GoogleFonts.nunito(
                                  color: theme.textSub,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: state.isAppLockEnabled,
                          activeTrackColor: theme.accent,
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            context.read<SecurityBloc>().add(ToggleAppLock(val));
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Privacy Features
                  NeuBox(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_rounded, size: 18, color: theme.accent),
                            const SizedBox(width: 8),
                            Text(
                              'Privacy Shield Protection',
                              style: GoogleFonts.nunito(
                                color: theme.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'When enabled, Folio automatically blurs its screen preview in the OS task switcher, preventing unauthorized glances at sensitive documents.',
                          style: GoogleFonts.nunito(
                            color: theme.textSub,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
