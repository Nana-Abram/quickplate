import 'package:intl/intl.dart';

/// Money is stored as integer pesewas (GHS 1 = 100 pesewas) everywhere and
/// only turned into text here, at the edge of the UI.
abstract final class Money {
  static final NumberFormat _cedis = NumberFormat.currency(
    locale: 'en',
    symbol: 'GH₵',
    decimalDigits: 2,
  );

  /// 4550 -> "GH₵45.50".
  static String format(int pesewas) => _cedis.format(pesewas / 100);

  /// Like [format], but 0 reads as "Free" (e.g. a delivery fee).
  static String formatFee(int pesewas) =>
      pesewas == 0 ? 'Free' : format(pesewas);
}
