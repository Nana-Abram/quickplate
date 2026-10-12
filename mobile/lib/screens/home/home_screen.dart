import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/restaurants_provider.dart';
import 'widgets/category_chips.dart';
import 'widgets/featured_carousel.dart';
import 'widgets/home_header.dart';
import 'widgets/offline_banner.dart';
import 'widgets/restaurant_list.dart';
import 'widgets/section_title.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Deferred: the first load notifies listeners, which is not allowed
    // while this screen is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RestaurantsProvider>().loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Light status bar icons over the orange header, with no scrim, so the
    // gradient runs to the top edge.
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: RestaurantList(
          header: [
            SliverToBoxAdapter(child: HomeHeader()),
            SliverToBoxAdapter(child: OfflineBanner()),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 16),
                child: CategoryChips(),
              ),
            ),
            SliverToBoxAdapter(child: FeaturedCarousel()),
            SliverToBoxAdapter(child: _ListTitle()),
          ],
        ),
      ),
    );
  }
}

class _ListTitle extends StatelessWidget {
  const _ListTitle();

  @override
  Widget build(BuildContext context) {
    final filtered = context.select<RestaurantsProvider, bool>(
      (p) => p.hasFilters,
    );
    return SectionTitle(title: filtered ? 'Results' : 'All restaurants');
  }
}
