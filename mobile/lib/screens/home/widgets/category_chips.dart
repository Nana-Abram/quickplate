import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/restaurant_categories.dart';
import '../../../providers/restaurants_provider.dart';
import '../../../widgets/app_network_image.dart';

/// Category filters as round dish photos with a label, plus "All".
class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  static const double _imageSize = 64;

  @override
  Widget build(BuildContext context) {
    final selected = context.select<RestaurantsProvider, String?>(
      (p) => p.category,
    );
    final provider = context.read<RestaurantsProvider>();
    const categories = <RestaurantCategory?>[null, ...RestaurantCategories.all];
    // The row scrolls sideways, so its height must be fixed up front; leave
    // room for labels at large text sizes.
    final labelHeight = MediaQuery.textScalerOf(context).scale(14) * 1.5;

    return SizedBox(
      height: _imageSize + 28 + labelHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final category = categories[index];
          final name = category?.name;
          return _CategoryTile(
            label: name ?? 'All',
            imageUrl: category?.imageUrl,
            selected: name == selected,
            onTap: () => provider.selectCategory(name),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const size = CategoryChips._imageSize;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label category',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: size + 12,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? scheme.primary : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: SizedBox.square(
                    dimension: size,
                    child: imageUrl == null
                        ? ColoredBox(
                            color: scheme.primaryContainer,
                            child: Icon(
                              Icons.restaurant_menu,
                              color: scheme.onPrimaryContainer,
                            ),
                          )
                        : AppNetworkImage(url: imageUrl!),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected ? scheme.primary : scheme.onSurface,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
