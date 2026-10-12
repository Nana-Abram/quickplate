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

    return ExcludeSemantics(
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        // Decode at display size rather than the full 600x400 source.
        memCacheWidth: width == null
            ? null
            : (width! * MediaQuery.devicePixelRatioOf(context)).round(),
        placeholder: (_, _) =>
            ColoredBox(color: scheme.surfaceContainerHighest),
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}
