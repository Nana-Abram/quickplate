import 'package:flutter/material.dart';

import '../../../data/models/menu_item.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/price_text.dart';

class MenuItemTile extends StatelessWidget {
  const MenuItemTile({super.key, required this.item, this.onTap});

  final MenuItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: item.isAvailable ? 1 : 0.5,
      child: InkWell(
        onTap: item.isAvailable ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: theme.textTheme.titleSmall),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PriceText(item.pricePesewas),
                        if (!item.isAvailable)
                          Text(
                            'Unavailable',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppNetworkImage(
                  url: item.imageUrl,
                  width: 88,
                  height: 88,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
