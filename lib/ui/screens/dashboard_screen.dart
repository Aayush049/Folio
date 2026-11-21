import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../blocs/scanner/scanner_bloc.dart';
import '../../blocs/scanner/scanner_event.dart';
import '../../blocs/auth_sync/auth_sync_bloc.dart';
import '../../blocs/auth_sync/auth_sync_state.dart';
import '../../blocs/trash/trash_bloc.dart';
import '../../blocs/trash/trash_event.dart';
import '../../blocs/trash/trash_state.dart';
import '../../blocs/security/security_bloc.dart';
import '../../blocs/security/security_state.dart';
import '../../repositories/document_repository.dart';
import '../widgets/document_list_tile.dart';
import '../widgets/folder_list_tile.dart';
import '../widgets/neu_widgets.dart';
import '../widgets/folio_logo.dart';
import '../widgets/cloud_sync_modal.dart';
import '../widgets/vault_lock_overlay.dart';
import '../../core/folio_theme.dart';
import '../../core/folio_breakpoints.dart';
import '../../core/folio_shortcuts.dart';
import '../../core/navigation_utils.dart';
import 'scanner_screen.dart';
import 'document_detail_screen.dart';
import 'documents_by_folder_screen.dart';
import 'search_screen.dart';
import 'trash_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToScanner() {
    HapticFeedback.lightImpact();
    context.read<ScannerBloc>().add(ResetScanner());
    Navigator.push(
      context,
      neuRoute(const ScannerScreen()),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 🌤';
    if (h < 21) return 'Good Evening 🌙';
    return 'Good Night 🌟';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<FolioThemeNotifier>();
    final isCompact = context.isCompact;

    return FolioShortcuts(
      onNewScan: _navigateToScanner,
      child: Scaffold(
        backgroundColor: theme.bg,
        body: SafeArea(
          child: ResponsiveContainer(
            maxWidth: FolioBreakpoints.maxContentWidth,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: !isCompact,
              child: BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  return CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Header Row
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _greeting(),
                                      style: GoogleFonts.nunito(
                                        color: theme.textSub,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const FolioLogo(
                                          size: 34,
                                          showShadow: true,
                                          borderRadius: 10,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Folio',
                                          style: GoogleFonts.nunito(
                                            color: theme.text,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Vault Lock Button
                              _SecurityVaultButton(),
                              const SizedBox(width: 8),
                              // Cloud Sync Vault Button
                              _CloudSyncButton(),
                              const SizedBox(width: 8),
                              // Theme toggle
                              _ThemeToggleButton(),
                              const SizedBox(width: 10),
                              // Scan button
                              NeuButton(
                                filled: true,
                                borderRadius: 20,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                onTap: _navigateToScanner,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      isCompact ? 'Scan' : 'New Scan (Ctrl+N)',
                                      style: GoogleFonts.nunito(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Full-Text OCR Search Bar & Trash Action Row
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: NeuBox(
                                  borderRadius: 18,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(context, neuRoute(const SearchScreen()));
                                  },
                                  child: Row(
                                    children: [
                                      Icon(Icons.search_rounded, color: theme.accent, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Search scans & OCR text contents...',
                                          style: GoogleFonts.nunito(
                                            color: theme.textSub.withValues(alpha: 0.8),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.accentSoft,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'FTS5',
                                          style: TextStyle(
                                            color: theme.accent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _TrashButton(),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 12)),

                      // ─── Body ─────────────────────────────────────────────────────
                      if (state is DashboardInitial || state is DashboardLoading)
                        const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (state is DashboardError)
                        SliverFillRemaining(child: _buildError(context, state))
                      else if (state is DashboardLoaded) ...[
                          _buildSectionHeader(
                            context,
                            'Folders',
                            count: state.folders.length,
                            onAdd: () => _showAddFolderDialog(context),
                          ),
                          _buildFolderSection(context, state, isCompact),
                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                          _buildSectionHeader(
                            context,
                            'Recent Scans',
                            count: state.recentDocuments.length,
                          ),
                          _buildRecentSection(context, state, isCompact),
                          const SliverToBoxAdapter(child: SizedBox(height: 36)),
                        ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, DashboardError state) {
    final theme = context.watch<FolioThemeNotifier>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 56, color: theme.textSub),
        const SizedBox(height: 16),
        Text(state.message, style: TextStyle(color: theme.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        NeuButton(
          onTap: () => context.read<DashboardBloc>().add(const LoadDashboard()),
          child: Text('Retry', style: TextStyle(color: context.watch<FolioThemeNotifier>().accent, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildSectionHeader(
    BuildContext context,
    String title, {
    int? count,
    VoidCallback? onAdd,
  }) {
    final theme = context.watch<FolioThemeNotifier>();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 16, 14),
        child: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.nunito(
                color: theme.text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: theme.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (onAdd != null)
              NeuIconButton(
                icon: Icons.create_new_folder_outlined,
                onTap: onAdd,
                size: 40,
                tooltip: 'New Folder',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderSection(BuildContext context, DashboardLoaded state, bool isCompact) {
    final theme = context.watch<FolioThemeNotifier>();
    if (state.folders.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: NeuBox(
            borderRadius: 16,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.folder_open_rounded, color: theme.textSub, size: 28),
                const SizedBox(width: 12),
                Text(
                  'No folders yet. Create one above.',
                  style: TextStyle(color: theme.textSub, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isCompact) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: state.folders.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final folder = state.folders[index];
              return FolderListTile(
                folder: folder,
                width: 124,
                onTap: () => Navigator.push(context, neuRoute(DocumentsByFolderScreen(folder: folder))),
                onDelete: () => context.read<DashboardBloc>().add(DeleteFolder(folder.id!)),
              );
            },
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisExtent: 115,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final folder = state.folders[index];
            return FolderListTile(
              folder: folder,
              onTap: () => Navigator.push(context, neuRoute(DocumentsByFolderScreen(folder: folder))),
              onDelete: () => context.read<DashboardBloc>().add(DeleteFolder(folder.id!)),
            );
          },
          childCount: state.folders.length,
        ),
      ),
    );
  }

  Widget _buildRecentSection(BuildContext context, DashboardLoaded state, bool isCompact) {
    final theme = context.watch<FolioThemeNotifier>();
    if (state.recentDocuments.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: NeuBox(
            borderRadius: 20,
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.document_scanner_outlined, size: 56, color: theme.textSub.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text(
                  'No scans yet',
                  style: TextStyle(color: theme.text, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap Scan (or press Ctrl+N) to get started',
                  style: TextStyle(color: theme.textSub, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: isCompact ? 800 : 560,
          mainAxisExtent: 88,
          crossAxisSpacing: 16,
          mainAxisSpacing: 14,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final doc = state.recentDocuments[index];
            return Hero(
              tag: 'doc_${doc.id}',
              child: DocumentListTile(
                doc: doc,
                onTap: () => Navigator.push(
                  context,
                  neuRoute(DocumentDetailScreen(
                    document: doc,
                    repository: context.read<DocumentRepository>(),
                  )),
                ),
                onDelete: () {
                  HapticFeedback.lightImpact();
                  context.read<DashboardBloc>().add(DeleteDocument(doc.id!));
                  context.read<TrashBloc>().add(const LoadTrash());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Moved "${doc.name}" to Trash'),
                      action: SnackBarAction(
                        label: 'Undo',
                        textColor: theme.accent,
                        onPressed: () {
                          context.read<TrashBloc>().add(RestoreDocumentFromTrash(doc.id!));
                          context.read<DashboardBloc>().add(const LoadDashboard());
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          },
          childCount: state.recentDocuments.length,
        ),
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    final theme = context.read<FolioThemeNotifier>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'New Folder',
          style: TextStyle(color: theme.text, fontWeight: FontWeight.w900),
        ),
        content: NeuTextField(
          controller: controller,
          label: 'Folder Name',
          prefixIcon: Icons.folder_outlined,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: theme.textSub, fontWeight: FontWeight.w700)),
          ),
          NeuButton(
            filled: true,
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            onTap: () {
              if (controller.text.isNotEmpty) {
                HapticFeedback.lightImpact();
                context.read<DashboardBloc>().add(AddFolder(controller.text));
                Navigator.pop(ctx);
              }
            },
            child: Text('Create', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ─── Trash & Recovery Button ──────────────────────────────────────────────────
class _TrashButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<FolioThemeNotifier>();
    return BlocBuilder<TrashBloc, TrashState>(
      builder: (context, state) {
        final count = (state is TrashLoaded) ? state.documents.length : 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            NeuIconButton(
              icon: Icons.delete_outline_rounded,
              size: 46,
              tooltip: 'Trash & Recovery',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(context, neuRoute(const TrashScreen()));
              },
            ),
            if (count > 0)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: theme.danger,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Security Vault Button ────────────────────────────────────────────────────
class _SecurityVaultButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SecurityBloc, SecurityState>(
      builder: (context, state) {
        return NeuIconButton(
          icon: state.isAppLockEnabled
              ? Icons.lock_outline_rounded
              : Icons.lock_open_rounded,
          active: state.isAppLockEnabled,
          tooltip: state.isAppLockEnabled
              ? 'Security Vault: Protected'
              : 'Security Vault: Open',
          onTap: () {
            HapticFeedback.lightImpact();
            showVaultSecuritySheet(context);
          },
          size: 44,
        );
      },
    );
  }
}

// ─── Cloud Sync Vault Button ──────────────────────────────────────────────────
class _CloudSyncButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthSyncBloc, AuthSyncState>(
      builder: (context, state) {
        final isAuth = state.isAuthenticated;
        final isBusy = state.isBusy;

        return NeuIconButton(
          icon: isBusy
              ? Icons.sync_rounded
              : (isAuth ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded),
          active: isAuth,
          tooltip: isAuth
              ? (isBusy ? 'Sync in progress...' : 'Cloud Backup (Connected)')
              : 'Cloud Backup & Sync (Offline)',
          onTap: () {
            HapticFeedback.lightImpact();
            showCloudSyncModal(context);
          },
          size: 44,
        );
      },
    );
  }
}

// ─── Theme Toggle ─────────────────────────────────────────────────────────────
class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<FolioThemeNotifier>();
    return GestureDetector(
      onLongPress: () {
        theme.setAuto();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Theme set to Auto (time-based)')),
        );
      },
      child: NeuIconButton(
        icon: theme.isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
        active: !theme.isAuto,
        tooltip: theme.isAuto ? 'Auto (long-press to reset)' : 'Manual override',
        onTap: () => theme.isDark ? theme.setDark(false) : theme.setDark(true),
        size: 44,
      ),
    );
  }
}
