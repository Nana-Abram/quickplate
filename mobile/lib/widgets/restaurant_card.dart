import 'package:flutter/material.dart';

import '../core/utils/money.dart';
import '../data/models/restaurant.dart';
import 'app_network_image.dart';
import 'rating_pill.dart';

/// A restaurant in the home list: a large dish photo with the rating on it,
/// then the name, cuisine and delivery facts.
class RestaurantCard extends StatelessWidget {
  const RestaurantCard({super.key, required this.restaurant, this.onTap});

  final Restaurant restaurant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(url: restaurant.imageUrl),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: RatingPill(rating: restaurant.rating),
                  ),
                  if (!restaurant.isOpen) const _ClosedOverlay(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(restaurant.categories.join(' · '), style: muted),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Fact(
                        icon: Icons.schedule_rounded,
                        label: '${restaurant.etaMinutes} min',
                        semanticLabel: 'About ${restaurant.etaMinutes} minutes',
                      ),
                      _Fact(
                        icon: Icons.delivery_dining_rounded,
                        label: Money.formatFee(restaurant.deliveryFeePesewas),
                        semanticLabel:
                            'Delivery ${Money.formatFee(restaurant.deliveryFeePesewas)}',
                        highlight: restaurant.deliveryFeePesewas == 0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = highlight
        ? scheme.tertiaryContainer
        : scheme.surfaceContainerHighest;
    final foreground = highlight
        ? scheme.onTertiaryContainer
        : scheme.onSurfaceVariant;

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClosedOverlay extends StatelessWidget {
  const _ClosedOverlay();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              'Closed',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
      ),
    );
  }
}
