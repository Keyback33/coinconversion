import 'package:coinconversion/features/currencies/currency_catalog.dart';
import 'package:coinconversion/shared/money_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatea importes con locale es_AR y decimales monetarios', () {
    final pen = MoneyFormatter.formatAmount(
      374.5,
      CurrencyCatalog.find('PEN')!,
    );
    final clp = MoneyFormatter.formatAmount(
      1234.6,
      CurrencyCatalog.find('CLP')!,
    );

    expect(pen, contains('374,50'));
    expect(pen, endsWith('PEN'));
    expect(clp, contains('1.235'));
    expect(clp, endsWith('CLP'));
  });

  test('usa notación científica para tasas demasiado pequeñas', () {
    expect(MoneyFormatter.formatRate(0.000000123), contains('e-7'));
  });

  test('una tasa positiva visible nunca se presenta como cero', () {
    expect(MoneyFormatter.formatRate(0.0000012), isNot('0'));
  });
}
