import '../currencies/currency_catalog.dart';

class RateSnapshot {
  factory RateSnapshot({
    required String baseCode,
    required Map<String, double> rates,
    required String providerId,
    required DateTime quotedAtUtc,
    required DateTime fetchedAtUtc,
    DateTime? nextUpdateAtUtc,
  }) {
    final normalizedBase = baseCode.toUpperCase();
    if (normalizedBase != 'USD') {
      throw ArgumentError.value(baseCode, 'baseCode');
    }
    if (providerId.trim().isEmpty) {
      throw ArgumentError.value(providerId, 'providerId');
    }

    final normalizedRates = <String, double>{};
    for (final entry in rates.entries) {
      final code = entry.key.toUpperCase();
      final rate = entry.value;
      if (code.length != 3 || !rate.isFinite || rate <= 0) {
        throw ArgumentError.value(entry, 'rates');
      }
      normalizedRates[code] = rate;
    }

    if (normalizedRates['USD'] != 1) {
      throw ArgumentError.value(rates['USD'], 'rates[USD]');
    }
    for (final currency in CurrencyCatalog.currencies) {
      if (!normalizedRates.containsKey(currency.code)) {
        throw ArgumentError('Falta la tasa ${currency.code}.');
      }
    }

    return RateSnapshot._(
      baseCode: normalizedBase,
      rates: Map.unmodifiable(normalizedRates),
      providerId: providerId,
      quotedAtUtc: quotedAtUtc.toUtc(),
      fetchedAtUtc: fetchedAtUtc.toUtc(),
      nextUpdateAtUtc: nextUpdateAtUtc?.toUtc(),
    );
  }

  const RateSnapshot._({
    required this.baseCode,
    required this.rates,
    required this.providerId,
    required this.quotedAtUtc,
    required this.fetchedAtUtc,
    required this.nextUpdateAtUtc,
  });

  final String baseCode;
  final Map<String, double> rates;
  final String providerId;
  final DateTime quotedAtUtc;
  final DateTime fetchedAtUtc;
  final DateTime? nextUpdateAtUtc;

  Map<String, Object?> toJson() => {
    'baseCode': baseCode,
    'rates': rates,
    'providerId': providerId,
    'quotedAtUtc': quotedAtUtc.toIso8601String(),
    'fetchedAtUtc': fetchedAtUtc.toIso8601String(),
    'nextUpdateAtUtc': nextUpdateAtUtc?.toIso8601String(),
  };

  factory RateSnapshot.fromJson(Map<String, Object?> json) {
    final rawRates = json['rates'];
    if (rawRates is! Map) {
      throw const FormatException('rates');
    }
    return RateSnapshot(
      baseCode: json['baseCode'] as String,
      rates: rawRates.map(
        (key, value) => MapEntry(key as String, (value as num).toDouble()),
      ),
      providerId: json['providerId'] as String,
      quotedAtUtc: DateTime.parse(json['quotedAtUtc'] as String),
      fetchedAtUtc: DateTime.parse(json['fetchedAtUtc'] as String),
      nextUpdateAtUtc: json['nextUpdateAtUtc'] == null
          ? null
          : DateTime.parse(json['nextUpdateAtUtc'] as String),
    );
  }
}
