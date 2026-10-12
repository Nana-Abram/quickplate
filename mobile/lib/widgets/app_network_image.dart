import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Cached image with a quiet placeholder and a fallback icon. Decorative:
/// screen readers skip it, the surrounding text describes the content.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.restaurant, color: scheme.onSurfaceVariant),
      ),
    );

    if (url.isEmpty) {
      return SizedBox(width: width, height: height, child: fallback);
    }

    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Decode at the size actually drawn, not the full source size:
          // less memory per image and faster first paint in long lists.
          final drawnWidth = width ?? constraints.maxWidth;
          return CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            memCacheWidth: drawnWidth.isFinite
                ? (drawnWidth * pixelRatio).round()
                : null,
            placeholder: (_, _) =>
                ColoredBox(color: scheme.surfaceContainerHighest),
            errorWidget: (_, _, _) => fallback,
          );
        },
      ),
    );
  }
}
