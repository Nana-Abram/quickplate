import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/empty_view.dart';

/// Placeholder until the restaurant list is built in Phase 4.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthProvider, String?>((p) => p.user?.email);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickPlate'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: EmptyView(
        icon: Icons.restaurant_outlined,
        title: 'Restaurants are coming soon',
        message: email == null ? null : 'Signed in as $email',
      ),
    );
  }
}
