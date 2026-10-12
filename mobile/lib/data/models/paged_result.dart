import 'package:flutter/foundation.dart';

/// One page of a cursor-paginated list.
@immutable
class PagedResult<T> {
  const PagedResult({required this.items, this.nextCursor});

  final List<T> items;

  /// Pass back to fetch the next page; null on the last page.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}
