import 'package:coinconversion/features/converter/amount_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('acepta coma, punto, cero y separador parcial', () {
    expect(AmountParser.parse('12,5').value, 12.5);
    expect(AmountParser.parse('12.5').value, 12.5);
    expect(AmountParser.parse('0').value, 0);
    expect(AmountParser.parse('12,').value, 12);
  });

  test('distingue campo vacío', () {
    final result = AmountParser.parse('');

    expect(result.isEmpty, isTrue);
    expect(result.isValid, isFalse);
    expect(result.error, isNull);
  });

  test('rechaza separadores ambiguos, negativos y exponentes', () {
    expect(AmountParser.parse('1,234.50').error, AmountParseError.invalid);
    expect(AmountParser.parse('-1').error, AmountParseError.invalid);
    expect(AmountParser.parse('1e3').error, AmountParseError.invalid);
  });

  test('aplica límites de precisión, longitud y monto', () {
    expect(
      AmountParser.parse('1,1234567').error,
      AmountParseError.tooManyDecimals,
    );
    expect(
      AmountParser.parse('1234567890123456789012345').error,
      AmountParseError.tooLong,
    );
    expect(
      AmountParser.parse('1000000000,01').error,
      AmountParseError.exceedsLimit,
    );
  });

  test('normaliza el separador sin alterar la precisión', () {
    expect(AmountParser.normalizeSeparator('12.3400'), '12,3400');
  });
}
