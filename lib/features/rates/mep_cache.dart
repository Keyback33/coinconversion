import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/app_failure.dart';
import 'mep_quote.dart';

class MepCache {
  MepCache(this._preferences, {DateTime Function()? nowUtc})
    : _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  static const key = 'mep_quote_v1';
  final SharedPreferencesAsync _preferences;
  final DateTime Function() _nowUtc;

  Future<MepQuote?> read() async {
    try {
      final encoded = await _preferences.getString(key);
      if (encoded == null) return null;
      final data = jsonDecode(encoded);
      if (data is! Map<String, dynamic> ||
          data['schemaVersion'] != 1 ||
          data['quote'] is! Map<String, dynamic>) {
        throw const FormatException('schema');
      }
      final quote = MepQuote.fromJson(data['quote'] as Map<String, dynamic>);
      if (!quote.isValidAt(_nowUtc())) throw const FormatException('future');
      return quote;
    } on Object {
      throw const AppFailure(AppFailureKind.storage);
    }
  }

  Future<void> write(MepQuote quote) async {
    try {
      await _preferences.setString(
        key,
        jsonEncode({'schemaVersion': 1, 'quote': quote.toJson()}),
      );
    } on Object {
      throw const AppFailure(AppFailureKind.storage);
    }
  }
}
