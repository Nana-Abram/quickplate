import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/empty_view.dart';

/// Placeholder until the restaurant list is built in Phase 4.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final greetingName = context.select<AuthProvider, String?>((p) {
      final name = p.user?.displayName;
      return name == null || name.isEmpty ? p.user?.email : name;
    });

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
      body: EmptyView(
        icon: Icons.restaurant_outlined,
        title: 'Restaurants are coming soon',
        message: greetingName == null ? null : 'Signed in as $greetingName',
      ),
    );
  }
}
