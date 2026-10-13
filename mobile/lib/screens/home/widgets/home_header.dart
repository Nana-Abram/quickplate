import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/routes.dart';
import '../../../core/theme/colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/cart_icon_button.dart';
import 'header_pattern.dart';
import 'restaurant_search_field.dart';

/// Warm gradient header with soft circles in the corner: greeting,
/// shortcuts and the search box. Starts in [AppColors.brandWarm], the colour
/// of the strip the home screen pins behind the status bar.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = context.select<AuthProvider, String?>(
      (p) => p.user?.displayName,
    );
    final firstName = displayName?.trim().split(' ').first ?? '';
    final greeting = firstName.isEmpty ? 'Akwaaba!' : 'Akwaaba, $firstName';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.brandWarm, AppColors.brandDeep],
          ),
        ),
        child: CustomPaint(
          painter: const HeaderPattern(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            greeting,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const _HeaderActions(),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 16),
                      child: Semantics(
                        header: true,
                        child: Text(
                          'What are you craving today?',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: _SearchBox(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions();

  @override
  Widget build(BuildContext context) {
    // White icons on the gradient, whatever the app's theme.
    return IconTheme.merge(
      data: const IconThemeData(color: Colors.white),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Your orders',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.push(Routes.orders),
          ),
          const CartIconButton(),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(Routes.profile),
          ),
        ],
      ),
    );
  }
}

/// The search field on a solid surface, so it reads the same in light and
/// dark mode on top of the gradient.
class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const RestaurantSearchField(),
    );
  }
}
