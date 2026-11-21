import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../blocs/search/search_bloc.dart';
import '../../blocs/search/search_event.dart';
import '../../blocs/search/search_state.dart';
import '../../core/folio_breakpoints.dart';
import '../../core/folio_theme.dart';
import '../../core/navigation_utils.dart';
import '../../repositories/document_repository.dart';
import '../widgets/neu_shimmer.dart';
import '../widgets/neu_widgets.dart';
import 'document_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<FolioThemeNotifier>();
    final isCompact = context.isCompact;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: FolioBreakpoints.maxContentWidth,
          child: Column(
            children: [
              // Search Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeuBox(
                        borderRadius: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: theme.accent, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                autofocus: true,
                                style: GoogleFonts.nunito(
                                  color: theme.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search documents & OCR text...',
                                  hintStyle: GoogleFonts.nunito(
                                    color: theme.textSub.withValues(alpha: 0.7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  context.read<SearchBloc>().add(SearchQueryChanged(val));
                                },
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  context.read<SearchBloc>().add(const ClearSearch());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(Icons.clear_rounded, size: 18, color: theme.textSub),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Search Results Body
              Expanded(
                child: BlocBuilder<SearchBloc, SearchState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return _buildShimmerLoading();
                    }

                    if (state.isEmptyQuery) {
                      return _buildEmptyQueryHint(theme);
                    }

                    if (!state.hasResults) {
                      return _buildNoResults(state.query, theme);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                          child: Row(
                            children: [
                              Text(
                                'Results for "${state.query}"',
                                style: GoogleFonts.nunito(
                                  color: theme.textSub,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.accentSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${state.results.length} found',
                                  style: TextStyle(
                                    color: theme.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: state.results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = state.results[index];
                              return _buildSearchResultTile(context, item, theme, isCompact);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultTile(
    BuildContext context,
    dynamic item,
    FolioThemeNotifier theme,
    bool isCompact,
  ) {
    final doc = item.document;
    final dateStr = DateFormat('MMM d, y').format(doc.createdAt);

    return NeuBox(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          neuRoute(DocumentDetailScreen(
            document: doc,
            repository: context.read<DocumentRepository>(),
          )),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.isTitleMatch
                      ? Icons.description_rounded
                      : Icons.text_snippet_rounded,
                  color: theme.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      style: GoogleFonts.nunito(
                        color: theme.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          item.folderName,
                          style: TextStyle(
                            color: theme.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          ' • $dateStr',
                          style: TextStyle(
                            color: theme.textSub,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.textSub, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.snippet,
              style: GoogleFonts.nunito(
                color: theme.textSub,
                fontSize: 12,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQueryHint(FolioThemeNotifier theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuBox(
              borderRadius: 30,
              padding: const EdgeInsets.all(24),
              child: Icon(
                Icons.travel_explore_rounded,
                size: 48,
                color: theme.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Full-Text OCR Search',
              style: GoogleFonts.nunito(
                color: theme.text,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search inside the actual text of contracts, receipts, passports, or scanned invoices.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: theme.textSub,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSearchChip('Invoice', theme),
                _buildSearchChip('Passport', theme),
                _buildSearchChip('Receipt', theme),
                _buildSearchChip('Agreement', theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchChip(String label, FolioThemeNotifier theme) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _searchController.text = label;
        context.read<SearchBloc>().add(SearchQueryChanged(label));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.accentSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: theme.accent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults(String query, FolioThemeNotifier theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: theme.textSub.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No matches found for "$query"',
              style: GoogleFonts.nunito(
                color: theme.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Searched both document names and on-device OCR scan contents.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: theme.textSub,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const NeuShimmer(width: double.infinity, height: 100, borderRadius: 18),
    );
  }
}
