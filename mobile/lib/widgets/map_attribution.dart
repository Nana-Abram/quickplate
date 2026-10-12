import 'package:flutter/material.dart';

import '../core/constants/map_config.dart';

/// The "© OpenStreetMap contributors" credit the tile policy requires. Unlike
/// flutter_map's built-in widget it shrinks to fit narrow maps and large text.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.bottomRight,
      child: ColoredBox(
        color: theme.colorScheme.surface.withValues(alpha: 0.85),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            '© ${MapConfig.attribution}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
        ),
      ),
    );
  }
}
