import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/restaurant_categories.dart';
import '../../../providers/restaurants_provider.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.select<RestaurantsProvider, String?>(
      (p) => p.category,
    );
    final provider = context.read<RestaurantsProvider>();
    const categories = <String?>[null, ...RestaurantCategories.all];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final category = categories[index];
          return ChoiceChip(
            label: Text(category ?? 'All'),
            selected: category == selected,
            onSelected: (_) => provider.selectCategory(category),
          );
        },
      ),
    );
  }
}
