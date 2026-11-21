import 'package:flutter/material.dart';

enum FolioScreenSize { compact, medium, expanded }

class FolioBreakpoints {
  static const double compact = 600.0;
  static const double expanded = 1024.0;
  static const double maxContentWidth = 1240.0;
}

extension FolioResponsiveX on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  FolioScreenSize get screenSize {
    final width = screenWidth;
    if (width < FolioBreakpoints.compact) {
      return FolioScreenSize.compact;
    } else if (width < FolioBreakpoints.expanded) {
      return FolioScreenSize.medium;
    } else {
      return FolioScreenSize.expanded;
    }
  }

  bool get isCompact => screenSize == FolioScreenSize.compact;
  bool get isMedium => screenSize == FolioScreenSize.medium;
  bool get isExpanded => screenSize == FolioScreenSize.expanded;

  /// Helper to pick a value based on the current screen size.
  T responsive<T>({required T compact, T? medium, T? expanded}) {
    switch (screenSize) {
      case FolioScreenSize.compact:
        return compact;
      case FolioScreenSize.medium:
        return medium ?? compact;
      case FolioScreenSize.expanded:
        return expanded ?? medium ?? compact;
    }
  }

  /// Responsive grid columns helper
  int responsiveColumns({int compact = 1, int medium = 2, int expanded = 3}) {
    return responsive(compact: compact, medium: medium, expanded: expanded);
  }
}

/// A wrapper widget that clamps content width for desktop/web and centers it
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = FolioBreakpoints.maxContentWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}
