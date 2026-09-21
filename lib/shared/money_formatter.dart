import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../features/converter/currency_converter.dart';
import '../features/currencies/currency.dart';

abstract final class MoneyFormatter {
  static const locale = 'es_AR';

  static String formatAmount(double value, Currency currency) {
    final rounded = CurrencyConverter.roundForCurrency(value, currency);
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: currency.symbol ?? currency.code,
      decimalDigits: currency.decimalDigits,
    );
    return '${formatter.format(rounded)} ${currency.code}';
  }

  static String formatRate(double value) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(value, 'value');
    }
    if (value < 0.000001) {
      return value.toStringAsExponential(5).replaceFirst('.', ',');
    }

    final integerDigits = value >= 1 ? math.log(value).floor() + 1 : 0;
    final decimalDigits = (6 - integerDigits).clamp(0, 12);
    return NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: decimalDigits,
    ).format(value);
  }
}
