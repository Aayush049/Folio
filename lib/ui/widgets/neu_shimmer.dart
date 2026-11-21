import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/folio_theme.dart';

class NeuShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const NeuShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 16,
  });

  @override
  State<NeuShimmer> createState() => _NeuShimmerState();
}

class _NeuShimmerState extends State<NeuShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<FolioThemeNotifier>();
    final isDark = theme.isDark;

    final baseColor = isDark
        ? const Color(0xFF202338)
        : const Color(0xFFD6DCE5);
    final highlightColor = isDark
        ? const Color(0xFF2C304C)
        : const Color(0xFFEDF2F7);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + (_controller.value * 3), -0.3),
              end: Alignment(0.5 + (_controller.value * 3), 0.3),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
            boxShadow: theme.subtleShadow,
          ),
        );
      },
    );
  }
}
