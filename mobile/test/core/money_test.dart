import 'package:flutter_test/flutter_test.dart';
import 'package:quickplate/core/utils/money.dart';

void main() {
  group('Money', () {
    test('formats pesewas as cedis with two decimals', () {
      expect(Money.format(4550), 'GH₵45.50');
      expect(Money.format(1000), 'GH₵10.00');
      expect(Money.format(5), 'GH₵0.05');
      expect(Money.format(0), 'GH₵0.00');
    });

    test('groups thousands', () {
      expect(Money.format(123456789), 'GH₵1,234,567.89');
    });

    test('formatFee reads 0 as Free', () {
      expect(Money.formatFee(0), 'Free');
      expect(Money.formatFee(1200), 'GH₵12.00');
    });
  });
}
