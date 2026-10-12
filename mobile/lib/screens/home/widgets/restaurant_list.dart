import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/routes.dart';
import '../../../data/models/restaurant.dart';
import '../../../providers/restaurants_provider.dart';
import '../../../providers/view_state.dart';
import '../../../widgets/empty_view.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/restaurant_card.dart';
import '../../../widgets/shimmer_list.dart';

/// Renders every state of the home list: loading, error, empty and the
/// paginated, pull-to-refresh list.
///
/// [header] slivers (greeting, search, categories) scroll with the list and
/// stay in place across states, so the search field keeps its text and
/// focus while results load.
class RestaurantList extends StatefulWidget {
  const RestaurantList({super.key, this.header = const []});

  final List<Widget> header;

  @override
  State<RestaurantList> createState() => _RestaurantListState();
}

class _RestaurantListState extends State<RestaurantList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    // Start fetching before the user reaches the very end.
    if (position.pixels >= position.maxScrollExtent - 400) {
      context.read<RestaurantsProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.select<RestaurantsProvider, ViewState>(
      (p) => p.state,
    );
    final provider = context.read<RestaurantsProvider>();

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: CustomScrollView(
        controller: _scrollController,
        // Pull-to-refresh must work even when the list is short.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ...widget.header,
          switch (state) {
            ViewState.idle || ViewState.loading => const SliverFillRemaining(
              hasScrollBody: false,
              child: SizedBox(
                height: 480,
                child: ShimmerList(itemCount: 3, itemHeight: 120),
              ),
            ),
            ViewState.error => SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorView(
                message: provider.errorMessage ?? 'Something went wrong.',
                onRetry: provider.retry,
              ),
            ),
            ViewState.empty => SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.search_off,
                title: 'No restaurants found',
                message: provider.hasFilters
                    ? 'Try a different search or category.'
                    : 'Check back soon.',
                actionLabel: provider.hasFilters ? 'Clear filters' : null,
                onAction: provider.hasFilters ? provider.clearFilters : null,
              ),
            ),
            ViewState.success => const _PagedSliver(),
          },
        ],
      ),
    );
  }
}

class _PagedSliver extends StatelessWidget {
  const _PagedSliver();

  @override
  Widget build(BuildContext context) {
    // Only the list and whether a footer exists matter here. The footer
    // watches its own loading and error state, so fetching the next page
    // does not rebuild every visible card.
    final (restaurants, showFooter) = context
        .select<RestaurantsProvider, (List<Restaurant>, bool)>(
          (p) => (p.restaurants, p.hasMore || p.loadMoreError != null),
        );

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList.separated(
        itemCount: restaurants.length + (showFooter ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == restaurants.length) return const _LoadMoreFooter();
          final restaurant = restaurants[index];
          return RestaurantCard(
            restaurant: restaurant,
            onTap: () => context.push(Routes.restaurantById(restaurant.id)),
          );
        },
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RestaurantsProvider>();
    final error = context.select<RestaurantsProvider, String?>(
      (p) => p.loadMoreError,
    );

    if (error != null) {
      return Column(
        children: [
          Text(error, textAlign: TextAlign.center),
          TextButton(
            onPressed: provider.loadMore,
            child: const Text('Try again'),
          ),
        ],
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
