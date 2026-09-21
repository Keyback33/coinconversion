import 'package:coinconversion/features/currencies/currency_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('contiene las siete monedas iniciales con sus decimales', () {
    expect(CurrencyCatalog.currencies.map((currency) => currency.code), [
      'ARS',
      'USD',
      'PEN',
      'EUR',
      'BRL',
      'CLP',
      'UYU',
    ]);
    expect(CurrencyCatalog.find('clp')?.decimalDigits, 0);
    expect(CurrencyCatalog.find('PEN')?.decimalDigits, 2);
  });

  test('busca por código o nombre sin distinguir acentos', () {
    expect(CurrencyCatalog.search('dolar').single.code, 'USD');
    expect(CurrencyCatalog.search('peN').single.code, 'PEN');
  });
}
