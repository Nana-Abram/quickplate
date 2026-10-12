import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';

/// Shared layout for the auth forms: centred, scrollable, width-capped for
/// tablets, with a title block above the form.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.showLogo = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showLogo)
                    Icon(
                      Icons.delivery_dining,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The last auth action's error, shown inline above the submit button and
/// announced to screen readers.
class AuthErrorText extends StatelessWidget {
  const AuthErrorText({super.key});

  @override
  Widget build(BuildContext context) {
    final message = context.select<AuthProvider, String?>(
      (p) => p.errorMessage,
    );
    if (message == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clears the previous form's result when an auth screen opens, so an error
/// from the login form does not show up on the register form.
mixin ResetAuthActionOnOpen<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    // Deferred: notifying listeners during the first build is not allowed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().resetActionState();
    });
  }
}
