import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Loading placeholder shaped like a list of image-and-text rows.
class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key, this.itemCount = 6, this.itemHeight = 88});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Loading',
      child: Shimmer.fromColors(
        baseColor: scheme.surfaceContainerHighest,
        highlightColor: scheme.surfaceContainerLow,
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (_, _) => _ShimmerRow(height: itemHeight),
        ),
      ),
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          _Block(width: height, height: height),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Block(height: 16),
                SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: _Block(height: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({this.width = double.infinity, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Shimmer paints over this colour; it only needs to be opaque.
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
