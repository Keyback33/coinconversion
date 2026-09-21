import 'package:flutter/material.dart';

@immutable
class CurrencyVisualIdentity {
  const CurrencyVisualIdentity({
    required this.flagAsset,
    required this.issuerLabel,
    required this.lightAccent,
    required this.darkAccent,
  });

  final String flagAsset;
  final String issuerLabel;
  final Color lightAccent;
  final Color darkAccent;

  Color accentFor(Brightness brightness) {
    return brightness == Brightness.dark ? darkAccent : lightAccent;
  }

  static const byCode = <String, CurrencyVisualIdentity>{
    'ARS': CurrencyVisualIdentity(
      flagAsset: 'assets/flags/ars.png',
      issuerLabel: 'Argentina',
      lightAccent: Color(0xFF0077B6),
      darkAccent: Color(0xFF38BDF8),
    ),
    'USD': CurrencyVisualIdentity(
      flagAsset: 'assets/flags/usd.png',
      issuerLabel: 'Estados Unidos',
      lightAccent: Color(0xFF1B7F3A),
      darkAccent: Color(0xFF4ADE80),
    ),
    'PEN': CurrencyVisualIdentity(
      flagAsset: 'assets/flags/pen.png',
      issuerLabel: 'Perú',
      lightAccent: Color(0xFF8B1E3F),
      darkAccent: Color(0xFFFB7185),
    ),
    'EUR': CurrencyVisualIdentity(
      flagAsset: 'assets/flags/eur.png',
      issuerLabel: 'Unión Europea',
      lightAccent: Color(0xFF6D28D9),
      darkAccent: Color(0xFFC084FC),
    ),
    'BRL': CurrencyVisualIdentity(
      flagAsset: 'assets/flags/brl.png',
      issuerLabel: 'Brasil',
      lightAccent: Color(0xFF806000),
      darkAccent: Color(0xFFFACC15),
    ),
    'CLP': CurrencyVisualIdentity(
      flagAsset: 'assets/flags/clp.png',
      issuerLabel: 'Chile',
      lightAccent: Color(0xFFC62828),
      darkAccent: Color(0xFFF87171),
    ),
    'UYU': CurrencyVisualIdentity(
      flagAsset: 'assets/flags/uyu.png',
      issuerLabel: 'Uruguay',
      lightAccent: Color(0xFF1D4ED8),
      darkAccent: Color(0xFF60A5FA),
    ),
  };

  static CurrencyVisualIdentity of(String code) {
    return byCode[code] ??
        const CurrencyVisualIdentity(
          flagAsset: '',
          issuerLabel: 'Emisor desconocido',
          lightAccent: Color(0xFF4B5563),
          darkAccent: Color(0xFFCBD5E1),
        );
  }
}
