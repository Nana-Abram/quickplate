import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/restaurant.dart';
import '../../providers/menu_provider.dart';
import '../../providers/view_state.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';
import '../../widgets/view_cart_bar.dart';
import 'widgets/menu_category_list.dart';
import 'widgets/restaurant_sliver_app_bar.dart';

class RestaurantScreen extends StatelessWidget {
  const RestaurantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final restaurant = context.select<MenuProvider, Restaurant?>(
      (p) => p.restaurant,
    );
    final state = context.select<MenuProvider, ViewState>((p) => p.state);

    // Opened from a deep link: nothing to draw a header with yet.
    if (restaurant == null) {
      return Scaffold(
        appBar: AppBar(),
        body: state == ViewState.error
            ? const _MenuError()
            : const ShimmerList(),
      );
    }

    if (state != ViewState.success) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            RestaurantSliverAppBar(restaurant: restaurant),
            SliverFillRemaining(
              child: switch (state) {
                ViewState.error => const _MenuError(),
                ViewState.empty => const EmptyView(
                  icon: Icons.menu_book_outlined,
                  title: 'No menu yet',
                  message: 'This restaurant has not added any dishes.',
                ),
                _ => const ShimmerList(),
              },
            ),
          ],
        ),
      );
    }

    final categories = context.read<MenuProvider>().categories;
    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        bottomNavigationBar: ViewCartBar(restaurantId: restaurant.id),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Lets each tab's list start below the pinned header.
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: RestaurantSliverAppBar(
                restaurant: restaurant,
                forceElevated: innerBoxIsScrolled,
                bottom: _SolidTabBar(
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [for (final c in categories) Tab(text: c.name)],
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              for (final c in categories) MenuCategoryList(category: c),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gives the tabs an opaque background so they stay readable over the
/// header image while it is expanded.
class _SolidTabBar extends StatelessWidget implements PreferredSizeWidget {
  const _SolidTabBar(this.tabBar);

  final TabBar tabBar;

  @override
  Size get preferredSize => tabBar.preferredSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }
}

class _MenuError extends StatelessWidget {
  const _MenuError();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MenuProvider>();
    return ErrorView(
      message: provider.errorMessage ?? 'Something went wrong.',
      onRetry: provider.load,
    );
  }
}
