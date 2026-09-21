import 'package:flutter/material.dart';

import '../currencies/currency_catalog.dart';

class UserPreferences {
  factory UserPreferences({
    required List<String> favoriteCodes,
    required String referenceCode,
    required String converterFromCode,
    required String converterToCode,
    required ThemeMode themeMode,
  }) {
    final validFavorites = <String>[];
    for (final code in favoriteCodes) {
      final normalized = code.toUpperCase();
      if (CurrencyCatalog.find(normalized) != null &&
          !validFavorites.contains(normalized)) {
        validFavorites.add(normalized);
      }
    }
    return UserPreferences._(
      favoriteCodes: List.unmodifiable(validFavorites),
      referenceCode: _validOrDefault(referenceCode, 'USD'),
      converterFromCode: _validOrDefault(converterFromCode, 'USD'),
      converterToCode: _validOrDefault(converterToCode, 'PEN'),
      themeMode: themeMode,
    );
  }

  const UserPreferences._({
    required this.favoriteCodes,
    required this.referenceCode,
    required this.converterFromCode,
    required this.converterToCode,
    required this.themeMode,
  });

  static final defaults = UserPreferences(
    favoriteCodes: const ['USD', 'ARS', 'PEN', 'EUR', 'BRL', 'CLP', 'UYU'],
    referenceCode: 'USD',
    converterFromCode: 'USD',
    converterToCode: 'PEN',
    themeMode: ThemeMode.system,
  );

  final List<String> favoriteCodes;
  final String referenceCode;
  final String converterFromCode;
  final String converterToCode;
  final ThemeMode themeMode;

  UserPreferences copyWith({
    List<String>? favoriteCodes,
    String? referenceCode,
    String? converterFromCode,
    String? converterToCode,
    ThemeMode? themeMode,
  }) {
    return UserPreferences(
      favoriteCodes: favoriteCodes ?? this.favoriteCodes,
      referenceCode: referenceCode ?? this.referenceCode,
      converterFromCode: converterFromCode ?? this.converterFromCode,
      converterToCode: converterToCode ?? this.converterToCode,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, Object?> toJson() => {
    'favoriteCodes': favoriteCodes,
    'referenceCode': referenceCode,
    'converterFromCode': converterFromCode,
    'converterToCode': converterToCode,
    'themeMode': themeMode.name,
  };

  factory UserPreferences.fromJson(Map<String, Object?> json) {
    final rawFavorites = json['favoriteCodes'];
    final themeName = json['themeMode'];
    return UserPreferences(
      favoriteCodes: rawFavorites is List
          ? rawFavorites.whereType<String>().toList()
          : UserPreferences.defaults.favoriteCodes,
      referenceCode: json['referenceCode'] is String
          ? json['referenceCode']! as String
          : 'USD',
      converterFromCode: json['converterFromCode'] is String
          ? json['converterFromCode']! as String
          : 'USD',
      converterToCode: json['converterToCode'] is String
          ? json['converterToCode']! as String
          : 'PEN',
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == themeName,
        orElse: () => ThemeMode.system,
      ),
    );
  }

  static String _validOrDefault(String code, String fallback) {
    final normalized = code.toUpperCase();
    return CurrencyCatalog.find(normalized) == null ? fallback : normalized;
  }
}
