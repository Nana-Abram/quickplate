import 'package:flutter/material.dart';

/// Shown while Firebase restores the session. The router leaves it as soon
/// as the auth state is known. Same background as the native splash, so the
/// hand-over is seamless.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Icon(
                  Icons.delivery_dining,
                  size: 56,
                  color: scheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'QuickPlate',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ghana’s favourite dishes, delivered',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
