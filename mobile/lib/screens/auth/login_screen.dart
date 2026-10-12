import 'package:flutter/material.dart';

import '../../widgets/empty_view.dart';

/// Placeholder until the sign-in form is built in Phase 3.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: const EmptyView(
        icon: Icons.lock_outline,
        title: 'You are signed out',
        message: 'Sign-in is on its way.',
      ),
    );
  }
}
