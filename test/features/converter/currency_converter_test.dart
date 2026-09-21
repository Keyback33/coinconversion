import 'package:coinconversion/features/converter/currency_converter.dart';
import 'package:coinconversion/features/currencies/currency_catalog.dart';
import 'package:coinconversion/features/rates/rate_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final snapshot = _snapshot();
  final usd = CurrencyCatalog.find('USD')!;
  final ars = CurrencyCatalog.find('ARS')!;
  final pen = CurrencyCatalog.find('PEN')!;

  test('convierte USD a PEN y ARS a PEN sin redondeo intermedio', () {
    expect(
      CurrencyConverter.convert(
        amount: 100,
        from: usd,
        to: pen,
        snapshot: snapshot,
      ),
      closeTo(374.5, 1e-12),
    );
    expect(
      CurrencyConverter.convert(
        amount: 14500,
        from: ars,
        to: pen,
        snapshot: snapshot,
      ),
      closeTo(37.45, 1e-12),
    );
  });

  test('la tasa inversa conserva la propiedad ida y vuelta', () {
    final forward = CurrencyConverter.rate(
      from: ars,
      to: pen,
      snapshot: snapshot,
    );
    final backward = CurrencyConverter.rate(
      from: pen,
      to: ars,
      snapshot: snapshot,
    );

    expect(forward * backward, closeTo(1, 1e-12));
  });

  test('identidad funciona sin snapshot y acepta cero', () {
    expect(
      CurrencyConverter.convert(amount: 0, from: usd, to: usd, snapshot: null),
      0,
    );
  });

  test('rechaza monto y resultado fuera de límites', () {
    expect(
      () => CurrencyConverter.convert(
        amount: CurrencyConverter.maxAmount + 1,
        from: usd,
        to: pen,
        snapshot: snapshot,
      ),
      throwsA(
        isA<ConversionException>().having(
          (error) => error.failure,
          'failure',
          ConversionFailure.invalidAmount,
        ),
      ),
    );
    expect(
      () => CurrencyConverter.convert(
        amount: CurrencyConverter.maxAmount,
        from: usd,
        to: ars,
        snapshot: snapshot,
      ),
      throwsA(
        isA<ConversionException>().having(
          (error) => error.failure,
          'failure',
          ConversionFailure.resultTooLarge,
        ),
      ),
    );
  });

  test('redondea una vez según la moneda destino', () {
    expect(CurrencyConverter.roundForCurrency(10.125, pen), 10.13);
    expect(
      CurrencyConverter.roundForCurrency(1234.6, CurrencyCatalog.find('CLP')!),
      1235,
    );
  });
}

RateSnapshot _snapshot() {
  return RateSnapshot(
    baseCode: 'USD',
    rates: const {
      'USD': 1,
      'ARS': 1450,
      'PEN': 3.745,
      'EUR': 0.92,
      'BRL': 5.1,
      'CLP': 930,
      'UYU': 39.2,
    },
    providerId: 'fixture',
    quotedAtUtc: DateTime.utc(2026, 9, 20, 12),
    fetchedAtUtc: DateTime.utc(2026, 9, 20, 12, 5),
  );
}
