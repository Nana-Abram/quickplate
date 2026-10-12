import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/routes.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/restaurant.dart';
import '../../../providers/restaurants_provider.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/rating_pill.dart';
import 'section_title.dart';

/// "Top rated" row of large photo cards. Hidden while searching or
/// filtering, and when nothing qualifies.
class FeaturedCarousel extends StatelessWidget {
  const FeaturedCarousel({super.key});

  static const double _cardWidth = 280;

  @override
  Widget build(BuildContext context) {
    final featured = context.select<RestaurantsProvider, List<Restaurant>>(
      (p) => p.featured,
    );
    if (featured.isEmpty) return const SizedBox.shrink();

    final height = 200 + MediaQuery.textScalerOf(context).scale(16) * 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Top rated',
          subtitle: 'Kitchens people keep coming back to',
        ),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: featured.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final restaurant = featured[index];
              return SizedBox(
                width: _cardWidth,
                child: _FeaturedCard(
                  restaurant: restaurant,
                  onTap: () =>
                      context.push(Routes.restaurantById(restaurant.id)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.restaurant, required this.onTap});

  final Restaurant restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final facts =
        '${restaurant.etaMinutes} min  ·  '
        'Delivery ${Money.formatFee(restaurant.deliveryFeePesewas)}';

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(url: restaurant.imageUrl),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.35, 1],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: RatingPill(rating: restaurant.rating),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    facts,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelLarge?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
