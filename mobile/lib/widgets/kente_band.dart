import 'package:flutter/material.dart';

import '../core/theme/colors.dart';

/// A thin woven strip in kente colours, used as an accent under headers.
/// Painted, so it costs no image download and stays sharp at any width.
class KenteBand extends StatelessWidget {
  const KenteBand({super.key, this.height = 10});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: const CustomPaint(painter: _KentePainter()),
      ),
    );
  }
}

class _KentePainter extends CustomPainter {
  const _KentePainter();

  // One repeat of the weave: wide gold blocks broken by narrow green, red
  // and black bars, like the warp stripes of a kente strip.
  static const List<(Color, double)> _pattern = [
    (AppColors.kenteGold, 3),
    (AppColors.kenteGreen, 1),
    (AppColors.kenteBlack, 0.5),
    (AppColors.kenteRed, 1),
    (AppColors.kenteBlack, 0.5),
    (AppColors.kenteGold, 3),
    (AppColors.kenteRed, 1),
    (AppColors.kenteGreen, 1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.height;
    final paint = Paint();
    var x = 0.0;
    var row = 0;
    while (x < size.width) {
      for (final (color, width) in _pattern) {
        final w = width * unit;
        paint.color = color;
        // Offset alternate halves vertically for a woven look.
        final top = row.isEven ? 0.0 : size.height / 2;
        canvas
          ..drawRect(Rect.fromLTWH(x, 0, w, size.height), paint)
          ..drawRect(
            Rect.fromLTWH(x, top, w, size.height / 2),
            paint..color = Color.lerp(color, AppColors.kenteBlack, 0.18)!,
          );
        x += w;
        if (x >= size.width) break;
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(_KentePainter oldDelegate) => false;
}
