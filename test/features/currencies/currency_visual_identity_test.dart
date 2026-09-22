import 'package:coinconversion/features/currencies/currency_catalog.dart';
import 'package:coinconversion/features/currencies/currency_visual_identity.dart';
import 'package:coinconversion/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every catalog currency has a complete visual identity and asset',
    () async {
      expect(
        CurrencyVisualIdentity.byCode.keys.toSet(),
        CurrencyCatalog.currencies.map((currency) => currency.code).toSet(),
      );

      for (final currency in CurrencyCatalog.currencies) {
        final identity = CurrencyVisualIdentity.of(currency.code);
        expect(identity.issuerLabel, isNotEmpty);
        expect(identity.flagAsset, isNotEmpty);
        expect(
          (await rootBundle.load(identity.flagAsset)).lengthInBytes,
          greaterThan(0),
        );
      }
    },
  );

  test('currency accents meet non-text contrast on final surfaces', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final sections = theme.extension<AppSectionTheme>()!;
      for (final identity in CurrencyVisualIdentity.byCode.values) {
        final accent = identity.accentFor(theme.brightness);
        expect(
          _contrast(accent, sections.rates.surface),
          greaterThanOrEqualTo(3),
        );
        expect(
          _contrast(accent, sections.converter.surface),
          greaterThanOrEqualTo(3),
        );
      }
    }
  });
}

double _contrast(Color a, Color b) {
  final aLuminance = a.computeLuminance();
  final bLuminance = b.computeLuminance();
  return (aLuminance > bLuminance ? aLuminance + 0.05 : bLuminance + 0.05) /
      (aLuminance > bLuminance ? bLuminance + 0.05 : aLuminance + 0.05);
}
