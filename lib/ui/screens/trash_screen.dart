import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../blocs/trash/trash_bloc.dart';
import '../../blocs/trash/trash_event.dart';
import '../../blocs/trash/trash_state.dart';
import '../../core/folio_breakpoints.dart';
import '../../core/folio_theme.dart';
import '../widgets/neu_widgets.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  @override
  void initState() {
    super.initState();
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    NeuIconButton(
                      icon: Icons.arrow_back_rounded,
                      size: 44,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      tooltip: 'Back',
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
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Restore accidentally deleted scans',
                            style: GoogleFonts.nunito(
                              color: theme.textSub,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    BlocBuilder<TrashBloc, TrashState>(
                      builder: (context, state) {
                        final count = (state is TrashLoaded)
                            ? state.documents.length
                            : 0;
                        if (count == 0) return const SizedBox.shrink();

                        return NeuButton(
                          filled: false,
                          borderRadius: 14,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          onTap: () => _confirmEmptyTrash(context, theme),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_sweep_rounded,
                                color: theme.danger,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Empty',
                                style: TextStyle(
                                  color: theme.danger,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Content Body
              Expanded(
                child: BlocConsumer<TrashBloc, TrashState>(
                  listener: (context, state) {
                    if (state is TrashLoaded && state.message != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(state.message!)));
                      // Refresh dashboard in background
                      context.read<DashboardBloc>().add(const LoadDashboard());
                    }
                  },
                  builder: (context, state) {
                    if (state is TrashLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is TrashLoaded) {
                      if (state.documents.isEmpty) {
                        return _buildEmptyTrash(theme);
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: state.documents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = state.documents[index];
                          final deletedDate = doc.deletedAt != null
                              ? DateFormat(
                                  'MMM d, y • h:mm a',
                                ).format(doc.deletedAt!)
                              : 'Recently deleted';

                          return NeuBox(
                            borderRadius: 18,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.danger.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.name,
                                        style: GoogleFonts.nunito(
                                          color: theme.text,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Deleted $deletedDate',
                                        style: GoogleFonts.nunito(
                                          color: theme.textSub,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Restore action
                                IconButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    context.read<TrashBloc>().add(
                                      RestoreDocumentFromTrash(doc.id!),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.restore_from_trash_rounded,
                                    color: theme.accent,
                                    size: 22,
                                  ),
                                  tooltip: 'Restore Document',
                                ),
                                // Permanent delete action
                                IconButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _confirmPermanentDelete(
                                      context,
                                      doc.id!,
                                      doc.name,
                                      theme,
                                    );
                                  },
                                  icon: Icon(
                                    Icons.delete_forever_rounded,
                                    color: theme.danger,
                                    size: 22,
                                  ),
                                  tooltip: 'Delete Forever',
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTrash(FolioThemeNotifier theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuBox(
              borderRadius: 30,
              padding: const EdgeInsets.all(24),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 48,
                color: theme.textSub.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Trash is Empty',
              style: GoogleFonts.nunito(
                color: theme.text,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Documents deleted from your library will appear here for safe recovery.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: theme.textSub,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPermanentDelete(
    BuildContext context,
    int docId,
    String name,
    FolioThemeNotifier theme,
  ) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: theme.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Forever?',
          style: GoogleFonts.nunito(
            color: theme.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently erase "$name"? This cannot be undone.',
          style: GoogleFonts.nunito(color: theme.textSub, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.textSub,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          NeuButton(
            filled: true,
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            onTap: () {
              Navigator.pop(dlgCtx);
              context.read<TrashBloc>().add(PermanentlyDeleteFromTrash(docId));
            },
            child: Text(
              'Delete Forever',
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

  void _confirmEmptyTrash(BuildContext context, FolioThemeNotifier theme) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: theme.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Empty Trash?',
          style: GoogleFonts.nunito(
            color: theme.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'This will permanently delete all documents currently in the recycle bin.',
          style: GoogleFonts.nunito(color: theme.textSub, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.textSub,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          NeuButton(
            filled: true,
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            onTap: () {
              Navigator.pop(dlgCtx);
              context.read<TrashBloc>().add(const EmptyTrash());
            },
            child: Text(
              'Empty Trash',
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
