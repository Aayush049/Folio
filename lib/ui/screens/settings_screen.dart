import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../blocs/auth_sync/auth_sync_bloc.dart';
import '../../blocs/auth_sync/auth_sync_event.dart';
import '../../blocs/auth_sync/auth_sync_state.dart';
import '../../blocs/security/security_bloc.dart';
import '../../blocs/security/security_event.dart';
import '../../blocs/security/security_state.dart';
import '../../blocs/trash/trash_bloc.dart';
import '../../blocs/trash/trash_event.dart';
import '../../blocs/trash/trash_state.dart';
import '../../core/folio_breakpoints.dart';
import '../../core/folio_theme.dart';
import '../../core/navigation_utils.dart';
import '../widgets/neu_widgets.dart';
import '../widgets/cloud_sync_modal.dart';
import '../widgets/vault_lock_overlay.dart';
import 'trash_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh states when visiting settings
    context.read<AuthSyncBloc>().add(const CheckAuthSyncStatus());
    context.read<SecurityBloc>().add(const CheckSecurityStatus());
    context.read<TrashBloc>().add(const LoadTrash());
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<FolioThemeNotifier>();

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: FolioBreakpoints.maxContentWidth,
          child: BlocListener<AuthSyncBloc, AuthSyncState>(
            listener: (context, state) {
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: theme.danger,
                  ),
                );
              } else if (state.statusMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.statusMessage!),
                    backgroundColor: theme.accent,
                  ),
                );
              }
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              physics: const BouncingScrollPhysics(),
              children: [
                // Header
                Text(
                  'Settings',
                  style: GoogleFonts.nunito(
                    color: theme.text,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Account profile, cloud backup, security vault & preferences',
                  style: GoogleFonts.nunito(
                    color: theme.textSub,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),

                // ── 1. Profile & Authentication ──
                _buildProfileSection(context, theme),
                const SizedBox(height: 20),

                // ── 2. Cloud Backup & Sync ──
                _buildCloudSyncSection(context, theme),
                const SizedBox(height: 20),

                // ── 3. Privacy & Security Vault ──
                _buildSecurityVaultSection(context, theme),
                const SizedBox(height: 20),

                // ── 4. Appearance & Theme Switcher ──
                _buildThemeSection(context, theme),
                const SizedBox(height: 20),

                // ── 5. Trash & Recovery ──
                _buildTrashSection(context, theme),
                const SizedBox(height: 20),

                // ── 6. About Folio ──
                _buildAboutSection(context, theme),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Profile / Google Sign-In Card ───────────────────────────────────────────
  Widget _buildProfileSection(BuildContext context, FolioThemeNotifier theme) {
    return BlocBuilder<AuthSyncBloc, AuthSyncState>(
      builder: (context, state) {
        final user = state.user;
        final isAuth = state.isAuthenticated;
        final isBusy = state.isAuthenticating;

        return NeuBox(
          borderRadius: 22,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.accentSoft,
                      border: Border.all(
                        color: isAuth ? Colors.green : theme.accent,
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: isAuth && user?.photoURL != null
                        ? Image.network(
                            user!.photoURL!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildAvatarFallback(user, theme),
                          )
                        : _buildAvatarFallback(user, theme),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAuth
                              ? (user?.displayName ?? 'Folio User')
                              : 'Account & Profile',
                          style: GoogleFonts.nunito(
                            color: theme.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAuth
                              ? (user?.email ?? '')
                              : 'Sign in to sync your scans securely',
                          style: GoogleFonts.nunito(
                            color: theme.textSub,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isAuth ? Colors.green : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAuth ? 'Connected' : 'Offline local profile',
                              style: GoogleFonts.nunito(
                                color: isAuth ? Colors.green : theme.textSub,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (isBusy)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (isAuth)
                SizedBox(
                  width: double.infinity,
                  child: NeuButton(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _confirmSignOut(context);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: theme.danger,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sign Out',
                          style: GoogleFonts.nunito(
                            color: theme.danger,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: NeuButton(
                    filled: true,
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context
                          .read<AuthSyncBloc>()
                          .add(const SignInWithGoogleRequested());
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.g_mobiledata_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Sign In with Google',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarFallback(dynamic user, FolioThemeNotifier theme) {
    final initial = (user?.displayName?.isNotEmpty == true)
        ? user.displayName![0].toUpperCase()
        : 'F';
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.nunito(
          color: theme.accent,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = dialogContext.watch<FolioThemeNotifier>();
        return AlertDialog(
          backgroundColor: theme.bg,
          title: Text(
            'Sign Out',
            style: GoogleFonts.nunito(
              color: theme.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Your local documents remain safe on this device. Cloud sync will pause until you sign in again.',
            style: GoogleFonts.nunito(color: theme.textSub),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.nunito(
                  color: theme.textSub,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<AuthSyncBloc>().add(const SignOutRequested());
              },
              child: Text(
                'Sign Out',
                style: GoogleFonts.nunito(
                  color: theme.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Cloud Backup & Sync ─────────────────────────────────────────────────────
  Widget _buildCloudSyncSection(BuildContext context, FolioThemeNotifier theme) {
    return BlocBuilder<AuthSyncBloc, AuthSyncState>(
      builder: (context, state) {
        final isAuth = state.isAuthenticated;
        final isBusy = state.isBusy;
        final lastSyncStr = state.lastSyncedAt != null
            ? DateFormat('MMM d, y • h:mm a').format(state.lastSyncedAt!)
            : 'Never backed up';

        return NeuBox(
          borderRadius: 22,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.accentSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.cloud_sync_rounded,
                      color: theme.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cloud Backup & Sync',
                          style: GoogleFonts.nunito(
                            color: theme.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          isAuth ? 'Firestore & Storage: $lastSyncStr' : 'Requires Google sign-in',
                          style: GoogleFonts.nunito(
                            color: theme.textSub,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: NeuButton(
                      borderRadius: 14,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      onTap: isAuth && !isBusy
                          ? () {
                              HapticFeedback.lightImpact();
                              context
                                  .read<AuthSyncBloc>()
                                  .add(const BackupToCloudRequested());
                            }
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 16,
                            color: isAuth ? theme.text : theme.textSub.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            state.isSyncing ? 'Backing up...' : 'Backup',
                            style: GoogleFonts.nunito(
                              color: isAuth ? theme.text : theme.textSub.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeuButton(
                      borderRadius: 14,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      onTap: isAuth && !isBusy
                          ? () {
                              HapticFeedback.lightImpact();
                              context
                                  .read<AuthSyncBloc>()
                                  .add(const RestoreFromCloudRequested());
                            }
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_download_outlined,
                            size: 16,
                            color: isAuth ? theme.text : theme.textSub.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            state.isRestoring ? 'Restoring...' : 'Restore',
                            style: GoogleFonts.nunito(
                              color: isAuth ? theme.text : theme.textSub.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  showCloudSyncModal(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Detailed Sync & Storage Status',
                        style: GoogleFonts.nunito(
                          color: theme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: theme.accent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Privacy & Security Vault ────────────────────────────────────────────────
  Widget _buildSecurityVaultSection(
      BuildContext context, FolioThemeNotifier theme) {
    return BlocBuilder<SecurityBloc, SecurityState>(
      builder: (context, state) {
        final isLocked = state.isAppLockEnabled;

        return NeuBox(
          borderRadius: 22,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.accentSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.security_rounded,
                      color: theme.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security & Privacy Vault',
                          style: GoogleFonts.nunito(
                            color: theme.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          isLocked
                              ? 'Biometric & PIN app lock active'
                              : 'App lock disabled (open access)',
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
                    value: isLocked,
                    activeThumbColor: theme.accent,
                    activeTrackColor: theme.accentSoft,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      context.read<SecurityBloc>().add(ToggleAppLock(val));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: NeuButton(
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showVaultSecuritySheet(context);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_person_outlined,
                        size: 16,
                        color: theme.text,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Configure PIN & Privacy Shield',
                        style: GoogleFonts.nunito(
                          color: theme.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Appearance & Theme ──────────────────────────────────────────────────────
  Widget _buildThemeSection(BuildContext context, FolioThemeNotifier theme) {
    return NeuBox(
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  theme.isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  color: theme.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance & Theme',
                      style: GoogleFonts.nunito(
                        color: theme.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      theme.isAuto
                          ? 'Automatic (follows sunrise & sunset)'
                          : (theme.isDark ? 'Dark mode' : 'Light mode'),
                      style: GoogleFonts.nunito(
                        color: theme.textSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildThemeOption(
                label: 'Auto',
                icon: Icons.brightness_auto_rounded,
                isSelected: theme.isAuto,
                onTap: () => theme.setAuto(),
                theme: theme,
              ),
              const SizedBox(width: 10),
              _buildThemeOption(
                label: 'Light',
                icon: Icons.light_mode_rounded,
                isSelected: !theme.isAuto && !theme.isDark,
                onTap: () => theme.setDark(false),
                theme: theme,
              ),
              const SizedBox(width: 10),
              _buildThemeOption(
                label: 'Dark',
                icon: Icons.dark_mode_rounded,
                isSelected: !theme.isAuto && theme.isDark,
                onTap: () => theme.setDark(true),
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required FolioThemeNotifier theme,
  }) {
    return Expanded(
      child: NeuBox(
        pressed: isSelected,
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(vertical: 10),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? theme.accent : theme.textSub,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? theme.accent : theme.textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Trash & Recovery ────────────────────────────────────────────────────────
  Widget _buildTrashSection(BuildContext context, FolioThemeNotifier theme) {
    return BlocBuilder<TrashBloc, TrashState>(
      builder: (context, state) {
        final count = (state is TrashLoaded) ? state.documents.length : 0;

        return NeuBox(
          borderRadius: 22,
          padding: const EdgeInsets.all(20),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(context, neuRoute(const TrashScreen()));
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.danger,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trash & Recovery',
                      style: GoogleFonts.nunito(
                        color: theme.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      count == 0
                          ? 'Recycle bin is empty'
                          : '$count item${count == 1 ? '' : 's'} available to restore',
                      style: GoogleFonts.nunito(
                        color: theme.textSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.danger,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: theme.textSub,
              ),
            ],
          ),
        );
      },
    );
  }

  // ── About Folio ─────────────────────────────────────────────────────────────
  Widget _buildAboutSection(BuildContext context, FolioThemeNotifier theme) {
    return NeuBox(
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: theme.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Folio Document Studio',
                      style: GoogleFonts.nunito(
                        color: theme.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Version 2.1.0 • Offline-First',
                      style: GoogleFonts.nunito(
                        color: theme.textSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '100% On-Device MLKit OCR • SQLite FTS5 Full-Text Search • AES-256 Vault Protection • Optional Cloud Firestore Sync',
            style: GoogleFonts.nunito(
              color: theme.textSub,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
