import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Cross-platform image widget that seamlessly displays files from
/// local disk paths on mobile and browser blob / network URLs on web.
class FolioImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  const FolioImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  factory FolioImage.file(
    File file, {
    Key? key,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    return FolioImage(
      key: key,
      path: file.path,
      fit: fit,
      width: width,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('data:')) {
      try {
        final uriData = UriData.fromUri(Uri.parse(path));
        return Image.memory(
          uriData.contentAsBytes(),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) => Container(
            width: width,
            height: height,
            color: Colors.grey.withValues(alpha: 0.12),
            child: const Center(
              child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 28),
            ),
          ),
        );
      } catch (_) {}
    }

    final isWebOrUrl = kIsWeb ||
        path.startsWith('blob:') ||
        path.startsWith('http://') ||
        path.startsWith('https://');

    if (isWebOrUrl) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey.withValues(alpha: 0.08),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey.withValues(alpha: 0.12),
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 28),
          ),
        ),
      );
    }

    return Image.file(
      File(path),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.grey.withValues(alpha: 0.12),
        child: const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 28),
        ),
      ),
    );
  }
}
