import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/app_user.dart';
import '../../providers/auth_provider.dart';

/// Temporary profile: who is signed in, and sign out. Saved addresses and the
/// theme toggle arrive in Phase 9.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, AppUser?>((p) => p.user);
    final isBusy = context.select<AuthProvider, bool>((p) => p.isBusy);
    final name = user?.displayName;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(name == null || name.isEmpty ? 'No name set' : name),
            subtitle: const Text('Name'),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(user?.email ?? ''),
            subtitle: const Text('Email'),
          ),
          const Divider(),
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
