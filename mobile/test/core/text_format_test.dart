import 'package:flutter_test/flutter_test.dart';
import 'package:quickplate/core/utils/text_format.dart';

void main() {
  test('itemCount uses the singular for one', () {
    expect(TextFormat.itemCount(1), '1 item');
    expect(TextFormat.itemCount(0), '0 items');
    expect(TextFormat.itemCount(3), '3 items');
  });
}
