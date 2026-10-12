import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../providers/restaurants_provider.dart';
import 'widgets/category_chips.dart';
import 'widgets/restaurant_list.dart';
import 'widgets/restaurant_search_field.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickPlate'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(Routes.profile),
          ),
        ],
      ),
      body: const Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: RestaurantSearchField(),
          ),
          CategoryChips(),
          Expanded(child: RestaurantList()),
        ],
      ),
    );
  }
}
