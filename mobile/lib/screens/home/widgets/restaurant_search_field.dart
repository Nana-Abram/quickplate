import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/restaurants_provider.dart';

/// Search box. Every keystroke goes to the provider, which debounces it.
class RestaurantSearchField extends StatefulWidget {
  const RestaurantSearchField({super.key});

  @override
  State<RestaurantSearchField> createState() => _RestaurantSearchFieldState();
}

class _RestaurantSearchFieldState extends State<RestaurantSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: context.read<RestaurantsProvider>().query,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    context.read<RestaurantsProvider>().search('');
  }

  @override
  Widget build(BuildContext context) {
    // Keep the field in sync when filters are cleared from elsewhere.
    final query = context.select<RestaurantsProvider, String>((p) => p.query);
    if (query.isEmpty && _controller.text.trim().isNotEmpty) {
      _controller.clear();
    }

    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onChanged: context.read<RestaurantsProvider>().search,
      decoration: InputDecoration(
        hintText: 'Search restaurants',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder(
          valueListenable: _controller,
          builder: (_, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close),
                  onPressed: _clear,
                ),
        ),
      ),
    );
  }
}
