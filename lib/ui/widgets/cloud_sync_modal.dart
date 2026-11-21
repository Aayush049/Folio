import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../blocs/auth_sync/auth_sync_bloc.dart';
import '../../blocs/auth_sync/auth_sync_event.dart';
import '../../blocs/auth_sync/auth_sync_state.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../core/folio_theme.dart';
import 'neu_widgets.dart';

void showCloudSyncModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) => const CloudSyncModal(),
  );
}

class CloudSyncModal extends StatelessWidget {
  const CloudSyncModal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<FolioThemeNotifier>();
    final mediaQuery = MediaQuery.of(context);
    final isDark = theme.isDark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.85,
        maxWidth: 600,
      ),
      margin: EdgeInsets.only(
        left: mediaQuery.size.width > 600 ? (mediaQuery.size.width - 600) / 2 : 0,
        right: mediaQuery.size.width > 600 ? (mediaQuery.size.width - 600) / 2 : 0,
        bottom: mediaQuery.viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BlocConsumer<AuthSyncBloc, AuthSyncState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: theme.danger,
                ),
              );
            }
            if (state.statusMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.statusMessage!),
                  backgroundColor: theme.accent,
                ),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
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
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          state.isAuthenticated
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_queue_rounded,
                          color: theme.accent,
                          size: 26,
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
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              state.isAuthenticated
                                  ? 'Connected to Firebase Cloud'
                                  : 'Optional encrypted cloud vault',
                              style: GoogleFonts.nunito(
                                color: theme.textSub,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: theme.textSub),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Content based on authentication status
                  if (state.isAuthenticated)
                    _buildAuthenticatedView(context, state, theme)
                  else
                    _buildUnauthenticatedView(context, state, theme),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAuthenticatedView(
    BuildContext context,
    AuthSyncState state,
    FolioThemeNotifier theme,
  ) {
    final user = state.user;
    final syncDateStr = state.lastSyncedAt != null
        ? DateFormat('MMM d, y • h:mm a').format(state.lastSyncedAt!)
        : 'Never synced';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // User Profile Card
        NeuBox(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (user?.photoURL != null)
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(user!.photoURL!),
                  backgroundColor: theme.accent.withValues(alpha: 0.2),
                )
              else
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.accent,
                  child: Text(
                    (user?.displayName ?? user?.email ?? 'F')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Folio User',
                      style: GoogleFonts.nunito(
                        color: theme.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user?.email ?? '',
                      style: GoogleFonts.nunito(
                        color: theme.textSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: state.isBusy
                    ? null
                    : () {
                        context.read<AuthSyncBloc>().add(const SignOutRequested());
                      },
                icon: Icon(Icons.logout_rounded, color: theme.danger, size: 20),
                tooltip: 'Sign Out',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Sync Metadata Pill
        NeuBox(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.access_time_rounded, size: 18, color: theme.textSub),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Backup',
                      style: GoogleFonts.nunito(
                        color: theme.textSub,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      syncDateStr,
                      style: GoogleFonts.nunito(
                        color: theme.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.lastSyncedAt != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Encrypted',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action Buttons
        NeuButton(
          filled: true,
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(vertical: 16),
          onTap: state.isBusy
              ? null
              : () {
                  context.read<AuthSyncBloc>().add(const BackupToCloudRequested());
                },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.isSyncing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                state.isSyncing ? 'Backing up to Cloud...' : 'Back Up All Documents Now',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        NeuButton(
          filled: false,
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(vertical: 16),
          onTap: state.isBusy
              ? null
              : () => _confirmAndRestore(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.isRestoring)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: theme.accent,
                  ),
                )
              else
                Icon(Icons.cloud_download_rounded, color: theme.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                state.isRestoring ? 'Restoring Documents...' : 'Restore from Cloud Backup',
                style: GoogleFonts.nunito(
                  color: theme.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnauthenticatedView(
    BuildContext context,
    AuthSyncState state,
    FolioThemeNotifier theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NeuBox(
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.offline_pin_rounded, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Offline-First Guarantee',
                    style: GoogleFonts.nunito(
                      color: theme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Folio works 100% offline with on-device SQLite storage and OCR. Cloud backup is entirely optional.',
                style: GoogleFonts.nunito(
                  color: theme.textSub,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(Icons.security_rounded, 'End-to-end user isolation with Firestore Rules', theme),
              const SizedBox(height: 8),
              _buildFeatureItem(Icons.sync_rounded, 'Sync across phones, tablets, desktop & web', theme),
              const SizedBox(height: 8),
              _buildFeatureItem(Icons.restore_page_rounded, 'Restore documents & high-res scans anytime', theme),
            ],
          ),
        ),
        const SizedBox(height: 24),

        NeuButton(
          filled: true,
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(vertical: 16),
          onTap: state.isAuthenticating
              ? null
              : () {
                  context.read<AuthSyncBloc>().add(const SignInWithGoogleRequested());
                },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.isAuthenticating)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.g_mobiledata_rounded,
                    color: Color(0xFF4285F4),
                    size: 20,
                  ),
                ),
              const SizedBox(width: 10),
              Text(
                state.isAuthenticating ? 'Signing in with Google...' : 'Sign in with Google',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, FolioThemeNotifier theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.nunito(
              color: theme.textSub,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmAndRestore(BuildContext context) {
    final theme = context.read<FolioThemeNotifier>();
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: theme.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Restore from Cloud Backup?',
          style: GoogleFonts.nunito(
            color: theme.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'This will download and merge your cloud documents, folders, and scanned pages into this device.\n\nExisting files will not be lost.',
          style: GoogleFonts.nunito(
            color: theme.textSub,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.textSub, fontWeight: FontWeight.bold),
            ),
          ),
          NeuButton(
            filled: true,
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            onTap: () {
              Navigator.pop(dlgCtx);
              context.read<AuthSyncBloc>().add(const RestoreFromCloudRequested());
              // Refresh the dashboard after restore completes
              Future.delayed(const Duration(seconds: 3), () {
                if (context.mounted) {
                  context.read<DashboardBloc>().add(const LoadDashboard());
                }
              });
            },
            child: Text(
              'Restore',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
