import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/folder_model.dart';
import '../../core/folio_theme.dart';

class FolderListTile extends StatelessWidget {
  final Folder folder;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final double? width;

  const FolderListTile({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onDelete,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<FolioThemeNotifier>();
    // Guard default folder from deletion
    final canDelete = folder.id != 1;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: canDelete ? () => _confirmDelete(context, theme) : null,
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: theme.bg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: theme.raisedShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.folder_rounded,
                    color: theme.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  folder.name,
                  style: GoogleFonts.nunito(
                    color: theme.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat.yMMMd().format(folder.createdAt),
                  style: GoogleFonts.nunito(
                    color: theme.textSub,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FolioThemeNotifier theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Folder?', style: TextStyle(color: theme.text, fontWeight: FontWeight.w900)),
        content: Text(
          'This will delete "${folder.name}" and all its contents.',
          style: TextStyle(color: theme.textSub, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: theme.textSub, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
