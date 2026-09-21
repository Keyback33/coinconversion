import 'package:flutter/material.dart';

@immutable
class AppSectionStyle {
  const AppSectionStyle({
    required this.surface,
    required this.border,
    required this.icon,
  });

  final Color surface;
  final Color border;
  final Color icon;
}

@immutable
class AppSectionTheme extends ThemeExtension<AppSectionTheme> {
  const AppSectionTheme({
    required this.status,
    required this.rates,
    required this.converter,
  });

  final AppSectionStyle status;
  final AppSectionStyle rates;
  final AppSectionStyle converter;

  @override
  AppSectionTheme copyWith({
    AppSectionStyle? status,
    AppSectionStyle? rates,
    AppSectionStyle? converter,
  }) {
    return AppSectionTheme(
      status: status ?? this.status,
      rates: rates ?? this.rates,
      converter: converter ?? this.converter,
    );
  }

  @override
  AppSectionTheme lerp(covariant AppSectionTheme? other, double t) {
    if (other == null) {
      return this;
    }
    return AppSectionTheme(
      status: _lerpStyle(status, other.status, t),
      rates: _lerpStyle(rates, other.rates, t),
      converter: _lerpStyle(converter, other.converter, t),
    );
  }

  static AppSectionStyle _lerpStyle(
    AppSectionStyle a,
    AppSectionStyle b,
    double t,
  ) {
    return AppSectionStyle(
      surface: Color.lerp(a.surface, b.surface, t)!,
      border: Color.lerp(a.border, b.border, t)!,
      icon: Color.lerp(a.icon, b.icon, t)!,
    );
  }
}

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2854C5),
      brightness: brightness,
    );
    final sections = brightness == Brightness.light
        ? const AppSectionTheme(
            status: AppSectionStyle(
              surface: Color(0xFFE8F2FF),
              border: Color(0xFF315B85),
              icon: Color(0xFF185A8D),
            ),
            rates: AppSectionStyle(
              surface: Color(0xFFF2EDFF),
              border: Color(0xFF6743A5),
              icon: Color(0xFF5D389B),
            ),
            converter: AppSectionStyle(
              surface: Color(0xFFE7F7F1),
              border: Color(0xFF21715B),
              icon: Color(0xFF17634F),
            ),
          )
        : const AppSectionTheme(
            status: AppSectionStyle(
              surface: Color(0xFF172638),
              border: Color(0xFF6DB5F7),
              icon: Color(0xFF8CC8FF),
            ),
            rates: AppSectionStyle(
              surface: Color(0xFF261E38),
              border: Color(0xFFC0A4FF),
              icon: Color(0xFFD0BAFF),
            ),
            converter: AppSectionStyle(
              surface: Color(0xFF142A24),
              border: Color(0xFF62D2AD),
              icon: Color(0xFF78E2BE),
            ),
          );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      extensions: [sections],
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF8F9FD)
          : const Color(0xFF101218),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
