import 'package:flutter/material.dart';

import '../../../core/utils/money.dart';
import '../../../data/models/restaurant.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/rating_pill.dart';

/// Header image with the restaurant's details. Collapses into a pinned bar
/// that shows the name (and the category tabs, when given as [bottom]).
class RestaurantSliverAppBar extends StatelessWidget {
  const RestaurantSliverAppBar({
    super.key,
    required this.restaurant,
    this.bottom,
    this.forceElevated = false,
  });

  static const double _expandedHeight = 320;

  final Restaurant restaurant;
  final PreferredSizeWidget? bottom;
  final bool forceElevated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    final topPadding = MediaQuery.paddingOf(context).top;
    final collapsedHeight = topPadding + kToolbarHeight + bottomHeight;

    return SliverAppBar(
      pinned: true,
      expandedHeight: _expandedHeight,
      forceElevated: forceElevated,
      leading: Center(
        child: IconButton.filledTonal(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      bottom: bottom,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // 1 when fully expanded, 0 when collapsed.
          final expansion =
              ((constraints.maxHeight - collapsedHeight) /
                      (_expandedHeight + topPadding - collapsedHeight))
                  .clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: expansion,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(url: restaurant.imageUrl),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          // Dark at the top for the status bar, darker at
                          // the bottom so the name and description read
                          // on any photo.
                          colors: [
                            Colors.black38,
                            Colors.transparent,
                            Colors.black87,
                          ],
                          stops: [0, 0.25, 0.75],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: bottomHeight + 12,
                      child: _HeaderInfo(restaurant: restaurant),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: topPadding,
                left: 64,
                right: 16,
                height: kToolbarHeight,
                child: Opacity(
                  opacity: 1 - expansion,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      restaurant.name,
                      style: theme.textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const onImage = Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          restaurant.name,
          style: text.headlineMedium?.copyWith(color: onImage),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          restaurant.description,
          style: text.bodyMedium?.copyWith(color: Colors.white70),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            RatingPill(rating: restaurant.rating),
            _GlassFact(
              icon: Icons.schedule_rounded,
              label: '${restaurant.etaMinutes} min',
            ),
            _GlassFact(
              icon: Icons.delivery_dining_rounded,
              label:
                  'Delivery ${Money.formatFee(restaurant.deliveryFeePesewas)}',
            ),
          ],
        ),
        if (!restaurant.isOpen) ...[
          const SizedBox(height: 8),
          const Chip(
            avatar: Icon(Icons.schedule, size: 18),
            label: Text('Closed now. You can still browse the menu.'),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }
}

/// A translucent pill for facts on top of the header photo.
class _GlassFact extends StatelessWidget {
  const _GlassFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
