import 'currency.dart';

abstract final class CurrencyCatalog {
  static const currencies = [
    Currency(
      code: 'ARS',
      name: 'Peso argentino',
      symbol: r'$',
      decimalDigits: 2,
    ),
    Currency(
      code: 'USD',
      name: 'Dólar estadounidense',
      symbol: r'US$',
      decimalDigits: 2,
    ),
    Currency(code: 'PEN', name: 'Sol peruano', symbol: 'S/', decimalDigits: 2),
    Currency(code: 'EUR', name: 'Euro', symbol: '€', decimalDigits: 2),
    Currency(
      code: 'BRL',
      name: 'Real brasileño',
      symbol: r'R$',
      decimalDigits: 2,
    ),
    Currency(code: 'CLP', name: 'Peso chileno', symbol: r'$', decimalDigits: 0),
    Currency(
      code: 'UYU',
      name: 'Peso uruguayo',
      symbol: r'$',
      decimalDigits: 2,
    ),
  ];

  static final byCode = Map.unmodifiable({
    for (final currency in currencies) currency.code: currency,
  });

  static Currency? find(String code) => byCode[code.toUpperCase()];

  static List<Currency> search(String query) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return currencies;
    }

    return currencies
        .where((currency) {
          return _normalize(currency.code).contains(normalizedQuery) ||
              _normalize(currency.name).contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[áàäâ]'), 'a')
        .replaceAll(RegExp('[éèëê]'), 'e')
        .replaceAll(RegExp('[íìïî]'), 'i')
        .replaceAll(RegExp('[óòöô]'), 'o')
        .replaceAll(RegExp('[úùüû]'), 'u');
  }
}
