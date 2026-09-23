import 'package:coinconversion/features/rates/rate_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normaliza códigos, fechas y hace inmutables las tasas', () {
    final snapshot = _createSnapshot(baseCode: 'usd');

    expect(snapshot.baseCode, 'USD');
    expect(snapshot.quotedAtUtc.isUtc, isTrue);
    expect(() => snapshot.rates['ARS'] = 2, throwsUnsupportedError);
  });

  test('rechaza base, tasas y catálogo incompletos', () {
    expect(() => _createSnapshot(baseCode: 'EUR'), throwsArgumentError);
    expect(
      () => _createSnapshot(overrideRates: {'USD': 1, 'ARS': 1450}),
      throwsArgumentError,
    );
    expect(
      () => _createSnapshot(overrideRates: _rates()..['PEN'] = 0),
      throwsArgumentError,
    );
  });

  test('conserva fechas diarias y lee snapshots legacy', () {
    final legacy = _createSnapshot();
    expect(RateSnapshot.fromJson(legacy.toJson()).hasDailyDates, isFalse);
    final dates = {
      for (final code in _rates().keys) code: DateTime.utc(2026, 9, 20),
    }..['BRL'] = DateTime.utc(2026, 9, 19);
    final daily = RateSnapshot(
      baseCode: 'USD',
      rates: _rates(),
      providerId: 'frankfurter',
      quotedAtUtc: DateTime.utc(2026, 9, 19),
      fetchedAtUtc: DateTime.utc(2026, 9, 21),
      quotedDatesUtc: dates,
    );
    final restored = RateSnapshot.fromJson(daily.toJson());
    expect(restored.quotedAtFor('BRL'), DateTime.utc(2026, 9, 19));
    expect(restored.quotedAtFor('EUR'), DateTime.utc(2026, 9, 20));
  });
}

RateSnapshot _createSnapshot({
  String baseCode = 'USD',
  Map<String, double>? overrideRates,
}) {
  return RateSnapshot(
    baseCode: baseCode,
    rates: overrideRates ?? _rates(),
    providerId: 'fixture',
    quotedAtUtc: DateTime(2026, 9, 20, 12),
    fetchedAtUtc: DateTime(2026, 9, 20, 12, 5),
  );
}

Map<String, double> _rates() {
  return {
    'USD': 1,
    'ARS': 1450,
    'PEN': 3.745,
    'EUR': 0.92,
    'BRL': 5.1,
    'CLP': 930,
    'UYU': 39.2,
  };
}
