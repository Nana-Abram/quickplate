abstract final class TextFormat {
  /// "1 item", "3 items".
  static String itemCount(int count) => count == 1 ? '1 item' : '$count items';
}
