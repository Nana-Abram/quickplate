import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/routes.dart';
import '../../../providers/restaurants_provider.dart';
import '../../../providers/view_state.dart';
import '../../../widgets/empty_view.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/restaurant_card.dart';
import '../../../widgets/shimmer_list.dart';

/// Renders every state of the home list: loading, error, empty and the
/// paginated, pull-to-refresh list.
class RestaurantList extends StatelessWidget {
  const RestaurantList({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select<RestaurantsProvider, ViewState>(
      (p) => p.state,
    );
    final provider = context.read<RestaurantsProvider>();

    return switch (state) {
      ViewState.idle || ViewState.loading => const ShimmerList(itemHeight: 120),
      ViewState.error => ErrorView(
        message: provider.errorMessage ?? 'Something went wrong.',
        onRetry: provider.retry,
      ),
      ViewState.empty => EmptyView(
        icon: Icons.search_off,
        title: 'No restaurants found',
        message: provider.hasFilters
            ? 'Try a different search or category.'
            : 'Check back soon.',
        actionLabel: provider.hasFilters ? 'Clear filters' : null,
        onAction: provider.hasFilters ? provider.clearFilters : null,
      ),
      ViewState.success => const _PagedList(),
    };
  }
}

class _PagedList extends StatefulWidget {
  const _PagedList();

  @override
  State<_PagedList> createState() => _PagedListState();
}

class _PagedListState extends State<_PagedList> {
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
    final provider = context.watch<RestaurantsProvider>();
    final restaurants = provider.restaurants;
    final showFooter = provider.hasMore || provider.loadMoreError != null;

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.separated(
        controller: _scrollController,
        // Pull-to-refresh must work even when the list is short.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
