import 'package:flutter/material.dart';

import '../../../data/models/menu_item.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/price_text.dart';

/// A dish on the menu: name, description and price, with its photo and an
/// add badge on the right. The whole row opens the item sheet.
class MenuItemTile extends StatelessWidget {
  const MenuItemTile({super.key, required this.item, this.onTap});

  static const double _imageSize = 104;

  final MenuItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Opacity(
      opacity: item.isAvailable ? 1 : 0.5,
      child: InkWell(
        onTap: item.isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: theme.textTheme.titleMedium),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PriceText(
                          item.pricePesewas,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (!item.isAvailable)
                          Text(
                            'Unavailable',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox.square(
                dimension: _imageSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AppNetworkImage(
                        url: item.imageUrl,
                        width: _imageSize,
                        height: _imageSize,
                      ),
                    ),
                    if (item.isAvailable)
                      Positioned(
                        right: -6,
                        bottom: -6,
                        // Decorative: the row itself is the button.
                        child: ExcludeSemantics(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.surface,
                                width: 3,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.add,
                                size: 20,
                                color: scheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
