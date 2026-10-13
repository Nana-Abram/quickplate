import 'package:flutter/material.dart';

/// Soft, overlapping translucent circles in the header's top-right corner.
/// Painted, so it costs no image and stays sharp at any size.
class HeaderPattern extends CustomPainter {
  const HeaderPattern();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.07);
    final w = size.width;
    final h = size.height;
    // Kept below the top edge: the strip behind the status bar is flat, so
    // a circle cut off there would leave a visible seam.
    canvas
      ..drawCircle(Offset(w + 10, h * 0.5), w * 0.3, paint)
      ..drawCircle(Offset(w * 0.7, h * 0.22), w * 0.12, paint)
      ..drawCircle(Offset(w * 0.1, h * 1.05), w * 0.22, paint);
  }

  @override
  bool shouldRepaint(HeaderPattern oldDelegate) => false;
}
