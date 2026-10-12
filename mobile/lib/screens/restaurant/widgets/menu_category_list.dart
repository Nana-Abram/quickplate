import 'package:flutter/material.dart';

import '../../../data/models/menu_category.dart';
import 'menu_item_tile.dart';

/// One tab of the menu. Must sit inside the restaurant screen's
/// NestedScrollView, whose overlap handle it injects.
class MenuCategoryList extends StatelessWidget {
  const MenuCategoryList({super.key, required this.category});

  final MenuCategory category;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      // Keeps each tab's scroll position when switching tabs.
      key: PageStorageKey(category.name),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList.separated(
            itemCount: category.items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) =>
                MenuItemTile(item: category.items[index]),
          ),
        ),
      ],
    );
  }
}
