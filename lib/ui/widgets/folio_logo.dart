import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/folio_theme.dart';

/// A custom-crafted, theme-reactive vector logo for Folio.
/// Features a layered neumorphic canvas, stacked document pages,
/// a folded corner (dog-ear), and an optional scanning beam animation.
class FolioLogo extends StatefulWidget {
  final double size;
  final bool animate;
  final bool showShadow;
  final double borderRadius;

  const FolioLogo({
    super.key,
    this.size = 100,
    this.animate = false,
    this.showShadow = true,
    this.borderRadius = 24,
  });

  @override
  State<FolioLogo> createState() => _FolioLogoState();
}

class _FolioLogoState extends State<FolioLogo>
    with SingleTickerProviderStateMixin {
  AnimationController? _animController;
  Animation<double>? _scanAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _animController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
      )..repeat(reverse: true);

      _scanAnimation = Tween<double>(begin: 0.15, end: 0.85).animate(
        CurvedAnimation(
          parent: _animController!,
          curve: Curves.easeInOutSine,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<FolioThemeNotifier>();
    final isDark = theme.isDark;
    final size = widget.size;
    final r = widget.borderRadius * (size / 100);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(r),
        boxShadow: widget.showShadow ? theme.raisedShadow : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.14),
        child: AnimatedBuilder(
          animation: _animController ?? const AlwaysStoppedAnimation(0.5),
          builder: (context, _) {
            final scanProgress = _scanAnimation?.value ?? 0.5;
            return CustomPaint(
              size: Size(size * 0.72, size * 0.72),
              painter: _FolioLogoPainter(
                accentColor: theme.accent,
                accentSoft: theme.accentSoft,
                textColor: theme.text,
                textSubColor: theme.textSub,
                cardBg: theme.cardBg,
                isDark: isDark,
                scanProgress: widget.animate ? scanProgress : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FolioLogoPainter extends CustomPainter {
  final Color accentColor;
  final Color accentSoft;
  final Color textColor;
  final Color textSubColor;
  final Color cardBg;
  final bool isDark;
  final double? scanProgress;

  _FolioLogoPainter({
    required this.accentColor,
    required this.accentSoft,
    required this.textColor,
    required this.textSubColor,
    required this.cardBg,
    required this.isDark,
    this.scanProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ─── 1. Background Sheet (Offset / Stacked Page) ─────────────────────────
    final backPagePaint = Paint()
      ..color = isDark
          ? accentColor.withValues(alpha: 0.25)
          : accentColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final backPageRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.04, w * 0.68, h * 0.82),
      Radius.circular(w * 0.14),
    );

    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.rotate(6 * math.pi / 180);
    canvas.translate(-w * 0.5, -h * 0.5);
    canvas.drawRRect(backPageRRect, backPagePaint);
    canvas.restore();

    // ─── 2. Front Main Document Sheet ─────────────────────────────────────────
    final docRect = Rect.fromLTWH(w * 0.08, h * 0.10, w * 0.70, h * 0.82);
    final docRadius = Radius.circular(w * 0.14);

    // Document drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.12)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        docRect.translate(w * 0.02, h * 0.04),
        docRadius,
      ),
      shadowPaint,
    );

    // Front page surface gradient
    final docPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Color.lerp(cardBg, Colors.white, 0.08)!,
                cardBg,
              ]
            : [
                Colors.white,
                Color.lerp(cardBg, Colors.white, 0.6)!,
              ],
      ).createShader(docRect);

    final docRRect = RRect.fromRectAndRadius(docRect, docRadius);
    canvas.drawRRect(docRRect, docPaint);

    // Document border stroke
    final borderPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02;
    canvas.drawRRect(docRRect, borderPaint);

    // ─── 3. Top-Right Folded Corner (Dog-Ear / Origami) ──────────────────────
    final foldSize = w * 0.22;
    final foldLeft = docRect.right - foldSize;
    final foldTop = docRect.top;

    final foldPath = Path()
      ..moveTo(foldLeft, foldTop)
      ..lineTo(docRect.right, foldTop + foldSize)
      ..lineTo(foldLeft + w * 0.04, foldTop + foldSize)
      ..arcToPoint(
        Offset(foldLeft, foldTop + foldSize - w * 0.04),
        radius: Radius.circular(w * 0.04),
      )
      ..close();

    final foldPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          accentColor,
          accentColor.withValues(alpha: 0.7),
        ],
      ).createShader(Rect.fromLTWH(foldLeft, foldTop, foldSize, foldSize));
    canvas.drawPath(foldPath, foldPaint);

    // ─── 4. Document Text Lines ──────────────────────────────────────────────
    final linePaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final lineX = docRect.left + w * 0.12;
    final lineMaxW = docRect.width - w * 0.24;

    // Header badge / title line
    final headerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(lineX, docRect.top + h * 0.20, lineMaxW * 0.45, h * 0.06),
      Radius.circular(h * 0.03),
    );
    linePaint.color = accentColor;
    canvas.drawRRect(headerRect, linePaint);

    // Text line 1
    final line1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(lineX, docRect.top + h * 0.34, lineMaxW * 0.85, h * 0.042),
      Radius.circular(h * 0.02),
    );
    linePaint.color = textSubColor.withValues(alpha: isDark ? 0.45 : 0.35);
    canvas.drawRRect(line1, linePaint);

    // Text line 2
    final line2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(lineX, docRect.top + h * 0.44, lineMaxW * 0.95, h * 0.042),
      Radius.circular(h * 0.02),
    );
    canvas.drawRRect(line2, linePaint);

    // Text line 3 (shorter)
    final line3 = RRect.fromRectAndRadius(
      Rect.fromLTWH(lineX, docRect.top + h * 0.54, lineMaxW * 0.60, h * 0.042),
      Radius.circular(h * 0.02),
    );
    canvas.drawRRect(line3, linePaint);

    // ─── 5. Signature / Stamp Accent at Bottom ───────────────────────────────
    final stampCenter = Offset(docRect.right - w * 0.20, docRect.bottom - h * 0.15);
    final stampRadius = w * 0.09;
    final stampPaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.35 : 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(stampCenter, stampRadius, stampPaint);

    final stampRingPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02;
    canvas.drawCircle(stampCenter, stampRadius, stampRingPaint);

    final checkPath = Path()
      ..moveTo(stampCenter.dx - stampRadius * 0.45, stampCenter.dy)
      ..lineTo(stampCenter.dx - stampRadius * 0.1, stampCenter.dy + stampRadius * 0.35)
      ..lineTo(stampCenter.dx + stampRadius * 0.45, stampCenter.dy - stampRadius * 0.35);

    final checkPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * 0.025;
    canvas.drawPath(checkPath, checkPaint);

    // ─── 6. Scanner Optical Laser Beam (Animated) ────────────────────────────
    if (scanProgress != null) {
      canvas.save();
      // Clip to document body
      canvas.clipRRect(docRRect);

      final beamY = docRect.top + (docRect.height * scanProgress!);
      final beamHeight = h * 0.12;

      // Glowing scan gradient
      final beamRect = Rect.fromLTWH(
        docRect.left,
        beamY - (beamHeight / 2),
        docRect.width,
        beamHeight,
      );

      final glowPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor.withValues(alpha: 0.0),
            accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
            accentColor.withValues(alpha: 0.0),
          ],
        ).createShader(beamRect);
      canvas.drawRect(beamRect, glowPaint);

      // Sharp central laser line
      final laserPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.1),
            accentColor,
            Colors.white,
            accentColor,
            accentColor.withValues(alpha: 0.1),
          ],
        ).createShader(Rect.fromLTWH(docRect.left, beamY - 1, docRect.width, 2))
        ..strokeWidth = w * 0.018;
      canvas.drawLine(
        Offset(docRect.left, beamY),
        Offset(docRect.right, beamY),
        laserPaint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FolioLogoPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor ||
        oldDelegate.cardBg != cardBg ||
        oldDelegate.isDark != isDark ||
        oldDelegate.scanProgress != scanProgress;
  }
}
