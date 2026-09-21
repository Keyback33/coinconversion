import 'package:coinconversion/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('section borders and icons meet non-text contrast', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final sections = theme.extension<AppSectionTheme>()!;
      for (final style in [
        sections.status,
        sections.rates,
        sections.converter,
      ]) {
        expect(_contrast(style.border, style.surface), greaterThanOrEqualTo(3));
        expect(_contrast(style.icon, style.surface), greaterThanOrEqualTo(3));
      }
    }
  });

  test('section text meets AA contrast', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final sections = theme.extension<AppSectionTheme>()!;
      for (final style in [
        sections.status,
        sections.rates,
        sections.converter,
      ]) {
        expect(
          _contrast(theme.colorScheme.onSurface, style.surface),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });
}

double _contrast(Color a, Color b) {
  final lighter = a.computeLuminance() > b.computeLuminance() ? a : b;
  final darker = identical(lighter, a) ? b : a;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
