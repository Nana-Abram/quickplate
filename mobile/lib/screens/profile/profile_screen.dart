import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../data/models/app_user.dart';
import '../../providers/auth_provider.dart';
import 'widgets/saved_addresses_section.dart';
import 'widgets/theme_mode_selector.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, AppUser?>((p) => p.user);
    final isBusy = context.select<AuthProvider, bool>((p) => p.isBusy);
    final theme = Theme.of(context);
    final name = user?.displayName;
    final hasName = name != null && name.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text(
                hasName ? name.characters.first.toUpperCase() : '?',
                semanticsLabel: '',
              ),
            ),
            title: Text(
              hasName ? name : 'No name set',
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(user?.email ?? ''),
          ),
          const _SectionTitle('Appearance'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ThemeModeSelector(),
          ),
          const _SectionTitle('Saved addresses'),
          const SavedAddressesSection(),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Your orders'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.orders),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            enabled: !isBusy,
            // The router returns to login once the session ends.
            onTap: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}
