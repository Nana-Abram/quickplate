import 'package:flutter/material.dart';

import '../../../core/utils/money.dart';
import '../../../data/models/restaurant.dart';
import '../../../widgets/app_network_image.dart';

/// Header image with the restaurant's details. Collapses into a pinned bar
/// that shows the name (and the category tabs, when given as [bottom]).
class RestaurantSliverAppBar extends StatelessWidget {
  const RestaurantSliverAppBar({
    super.key,
    required this.restaurant,
    this.bottom,
    this.forceElevated = false,
  });

  static const double _expandedHeight = 300;

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
                          colors: [Colors.transparent, Colors.black87],
                          stops: [0.3, 1],
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
    final facts = [
      '★ ${restaurant.rating.toStringAsFixed(1)}',
      '${restaurant.etaMinutes} min',
      'Delivery ${Money.formatFee(restaurant.deliveryFeePesewas)}',
    ].join('  ·  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          restaurant.name,
          style: text.headlineSmall?.copyWith(color: onImage),
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
        const SizedBox(height: 8),
        Text(facts, style: text.labelLarge?.copyWith(color: onImage)),
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
