import 'package:flutter/foundation.dart';

/// One page of a cursor-paginated list.
@immutable
class PagedResult<T> {
  const PagedResult({
    required this.items,
    this.nextCursor,
    this.fromCache = false,
  });

  final List<T> items;

  /// Pass back to fetch the next page; null on the last page.
  final String? nextCursor;

  /// True when the network failed and these are earlier results.
  final bool fromCache;

  bool get hasMore => nextCursor != null;
}
