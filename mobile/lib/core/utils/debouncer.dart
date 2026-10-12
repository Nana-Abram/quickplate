import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runs only the last action scheduled within [delay], e.g. one search
/// request after the user stops typing instead of one per keystroke.
class Debouncer {
  Debouncer(this.delay);

  final Duration delay;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();
}
