import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../../models/document_model.dart';
import '../../models/page_model.dart';
import '../../repositories/document_repository.dart';
import '../../services/pdf_service.dart';
import '../../services/scanner_service.dart';
import '../../core/folio_theme.dart';
import '../../core/folio_breakpoints.dart';
import '../../core/folio_shortcuts.dart';
import '../../core/navigation_utils.dart';
import '../../blocs/document_detail/document_detail_bloc.dart';
import '../../blocs/document_detail/document_detail_event.dart';
import '../../blocs/document_detail/document_detail_state.dart';
import '../widgets/neu_widgets.dart';
import '../widgets/folio_image.dart';
import 'studio_screen.dart';

class DocumentDetailScreen extends StatelessWidget {
  final Document document;
  final IDocumentRepository? repository;

  const DocumentDetailScreen({
    super.key,
    required this.document,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => DocumentDetailBloc(
        repository: repository ?? ctx.read<IDocumentRepository>(),
        scannerService: ctx.read<ScannerService>(),
        documentId: document.id!,
      )..add(LoadDocumentPages(document.id!)),
      child: _DocumentDetailView(document: document),
    );
  }
}

class _DocumentDetailView extends StatefulWidget {
  final Document document;
  const _DocumentDetailView({required this.document});

  @override
  State<_DocumentDetailView> createState() => _DocumentDetailViewState();
}

class _DocumentDetailViewState extends State<_DocumentDetailView> {
  final PdfService _pdfService = PdfService();
  bool _isReorderMode = false;

  void _showExtractedText(BuildContext context, String text) {
    final theme = context.read<FolioThemeNotifier>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: DraggableScrollableSheet(
            initialChildSize: 0.65,
            maxChildSize: 0.95,
            minChildSize: 0.4,
            builder: (_, controller) => Container(
              decoration: BoxDecoration(
                color: theme.bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: theme.darkShadow.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.textSub.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Icon(Icons.text_fields_rounded, color: theme.accent, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Extracted Text',
                          style: GoogleFonts.nunito(
                            color: theme.text,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        NeuButton(
                          borderRadius: 12,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied to clipboard')),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded, color: theme.accent, size: 16),
                              const SizedBox(width: 6),
                              Text('Copy', style: GoogleFonts.nunito(color: theme.accent, fontWeight: FontWeight.w800, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: NeuBox(
                        pressed: true,
                        borderRadius: 16,
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          text,
                          style: GoogleFonts.nunito(
                            color: theme.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportAndShare(List<PageModel> pages) async {
    if (pages.isEmpty) return;
    try {
      final images = pages.map((p) => File(p.imagePath)).toList();
      final pdfFile = await _pdfService.generatePdf(images, widget.document.name);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(pdfFile.path)],
          text: 'Document from Folio',
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _openPdf(List<PageModel> pages) async {
    if (pages.isEmpty) return;
    try {
      final images = pages.map((p) => File(p.imagePath)).toList();
      final pdfFile = await _pdfService.generatePdf(images, widget.document.name);
      await OpenFilex.open(pdfFile.path);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<FolioThemeNotifier>();

    return FolioShortcuts(
      onEscape: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: theme.bg,
        body: SafeArea(
          child: ResponsiveContainer(
            maxWidth: 1080,
            child: BlocConsumer<DocumentDetailBloc, DocumentDetailState>(
              listener: (context, state) {
                if (state is DocumentDetailLoaded && state.extractedOcrText != null) {
                  _showExtractedText(context, state.extractedOcrText!);
                }
                if (state is DocumentDetailError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                final pages = state is DocumentDetailLoaded ? state.pages : <PageModel>[];
                final isExtracting = state is DocumentDetailLoaded && state.isExtractingOcr;

                return Column(
                  children: [
                    // ─── Header ──────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Row(
                        children: [
                          NeuIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => Navigator.pop(context),
                            size: 44,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              widget.document.name,
                              style: GoogleFonts.nunito(
                                color: theme.text,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ─── Action Row ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: Row(
                        children: [
                          NeuIconButton(
                            icon: _isReorderMode ? Icons.grid_view_rounded : Icons.reorder_rounded,
                            onTap: () => setState(() => _isReorderMode = !_isReorderMode),
                            active: _isReorderMode,
                            tooltip: _isReorderMode ? 'Grid View' : 'Reorder',
                            size: 44,
                          ),
                          const SizedBox(width: 10),
                          NeuIconButton(
                            icon: Icons.share_outlined,
                            onTap: () => _exportAndShare(pages),
                            size: 44,
                            tooltip: 'Share PDF',
                          ),
                          const SizedBox(width: 10),
                          NeuIconButton(
                            icon: Icons.picture_as_pdf_outlined,
                            onTap: () => _openPdf(pages),
                            size: 44,
                            tooltip: 'Open PDF',
                          ),
                          const SizedBox(width: 10),
                          // OCR button
                          isExtracting
                              ? SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: theme.accent),
                                    ),
                                  ),
                                )
                              : NeuIconButton(
                                  icon: Icons.text_fields_rounded,
                                  onTap: () => context.read<DocumentDetailBloc>().add(const ExtractDocumentOcrText()),
                                  size: 44,
                                  tooltip: 'Extract Text (OCR)',
                                ),
                          const Spacer(),
                          // Add pages button
                          NeuButton(
                            filled: true,
                            borderRadius: 14,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            onTap: () => _addPages(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_a_photo_outlined, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text('Add', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ─── Pages ──────────────────────────────────────────────
                    Expanded(
                      child: state is DocumentDetailLoading
                          ? const Center(child: CircularProgressIndicator())
                          : pages.isEmpty
                              ? Center(
                                  child: Text(
                                    'No pages found.',
                                    style: TextStyle(color: theme.textSub, fontWeight: FontWeight.w700),
                                  ),
                                )
                              : _isReorderMode
                                  ? _buildReorderableList(context, theme, pages)
                                  : _buildGrid(context, theme, pages),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, FolioThemeNotifier theme, List<PageModel> pages) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: pages.length,
      itemBuilder: (context, index) {
        final page = pages[index];
        return Hero(
          tag: 'page_${page.id}',
          child: Container(
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: theme.raisedShadow,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: FolioImage(
                    path: page.imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                // Top action buttons
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _PageActionButton(
                        icon: Icons.edit_outlined,
                        onTap: () async {
                          final editedImage = await Navigator.push<File>(
                            context,
                            neuRoute(StudioScreen(image: File(page.imagePath))),
                          );
                          if (editedImage != null && context.mounted) {
                            context.read<DocumentDetailBloc>().add(
                              UpdateDocumentPage(page.copyWith(imagePath: editedImage.path)),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      _PageActionButton(
                        icon: Icons.delete_outline_rounded,
                        danger: true,
                        onTap: () {
                          context.read<DocumentDetailBloc>().add(DeleteDocumentPage(page.id!));
                        },
                      ),
                    ],
                  ),
                ),
                // Page badge
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Page ${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReorderableList(BuildContext context, FolioThemeNotifier theme, List<PageModel> pages) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: pages.length,
      onReorder: (oldIndex, newIndex) {
        context.read<DocumentDetailBloc>().add(ReorderDocumentPages(oldIndex, newIndex));
      },
      itemBuilder: (context, index) {
        final page = pages[index];
        return Padding(
          key: ValueKey(page.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: theme.subtleShadow,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: FolioImage(path: page.imagePath, width: 52, height: 52, fit: BoxFit.cover),
              ),
              title: Text(
                'Page ${index + 1}',
                style: GoogleFonts.nunito(color: theme.text, fontWeight: FontWeight.w800),
              ),
              trailing: const MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Icon(Icons.drag_handle_rounded),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addPages(BuildContext context) async {
    final scannerService = context.read<ScannerService>();
    final theme = context.read<FolioThemeNotifier>();

    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: theme.textSub.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Add More Pages', style: GoogleFonts.nunito(color: theme.text, fontWeight: FontWeight.w900, fontSize: 18)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Row(
                      children: [
                        Expanded(
                          child: NeuButton(
                            borderRadius: 18,
                            padding: const EdgeInsets.all(20),
                            onTap: () => Navigator.pop(ctx, 'camera'),
                            child: Column(
                              children: [
                                Icon(Icons.camera_alt_outlined, color: theme.accent, size: 28),
                                const SizedBox(height: 8),
                                Text('Camera', style: GoogleFonts.nunito(color: theme.text, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: NeuButton(
                            borderRadius: 18,
                            padding: const EdgeInsets.all(20),
                            onTap: () => Navigator.pop(ctx, 'gallery'),
                            child: Column(
                              children: [
                                Icon(Icons.photo_library_outlined, color: theme.accent, size: 28),
                                const SizedBox(height: 8),
                                Text('Gallery', style: GoogleFonts.nunito(color: theme.text, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (source == null) return;
    List<File> newImages = [];
    if (source == 'camera') {
      final img = await scannerService.pickImageFromCamera();
      if (img != null) newImages.add(img);
    } else {
      newImages = await scannerService.pickImages();
    }

    if (newImages.isEmpty) return;
    if (!context.mounted) return;

    context.read<DocumentDetailBloc>().add(AddDocumentPages(newImages));
  }
}

// ─── Helper Widget ────────────────────────────────────────────────────────────
class _PageActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  const _PageActionButton({required this.icon, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: danger ? Colors.redAccent : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Icon(icon, size: 16, color: danger ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}
