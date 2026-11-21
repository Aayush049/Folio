import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralized keyboard shortcut intents for desktop and web
class NewScanIntent extends Intent {
  const NewScanIntent();
}

class SaveDocumentIntent extends Intent {
  const SaveDocumentIntent();
}

class EscapeIntent extends Intent {
  const EscapeIntent();
}

/// Global shortcut actions wrapper
class FolioShortcuts extends StatelessWidget {
  final Widget child;
  final VoidCallback? onNewScan;
  final VoidCallback? onSave;
  final VoidCallback? onEscape;

  const FolioShortcuts({
    super.key,
    required this.child,
    this.onNewScan,
    this.onSave,
    this.onEscape,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            const NewScanIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN):
            const NewScanIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            const SaveDocumentIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS):
            const SaveDocumentIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const EscapeIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          NewScanIntent: CallbackAction<NewScanIntent>(
            onInvoke: (_) {
              onNewScan?.call();
              return null;
            },
          ),
          SaveDocumentIntent: CallbackAction<SaveDocumentIntent>(
            onInvoke: (_) {
              onSave?.call();
              return null;
            },
          ),
          EscapeIntent: CallbackAction<EscapeIntent>(
            onInvoke: (_) {
              onEscape?.call();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}
