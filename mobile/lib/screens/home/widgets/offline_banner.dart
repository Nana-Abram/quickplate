import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/restaurants_provider.dart';

/// Explains that the list is from earlier because the network is down.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final showingCached = context.select<RestaurantsProvider, bool>(
      (p) => p.isShowingCached,
    );
    if (!showingCached) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: scheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            children: [
              Icon(Icons.cloud_off, color: scheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You are offline. Showing restaurants from earlier.',
                  style: TextStyle(color: scheme.onSecondaryContainer),
                ),
              ),
              TextButton(
                onPressed: context.read<RestaurantsProvider>().retry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
