import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/app_failure.dart';
import 'rate_snapshot.dart';

class RatesCache {
  RatesCache(this._preferences);

  static const key = 'rates_snapshot_v1';
  static const schemaVersion = 1;

  final SharedPreferencesAsync _preferences;

  Future<RateSnapshot?> read() async {
    try {
      final encoded = await _preferences.getString(key);
      if (encoded == null) {
        return null;
      }
      final json = jsonDecode(encoded);
      if (json is! Map<String, dynamic> ||
          json['schemaVersion'] != schemaVersion ||
          json['snapshot'] is! Map<String, dynamic>) {
        throw const FormatException('schema');
      }
      return RateSnapshot.fromJson(json['snapshot'] as Map<String, dynamic>);
    } on Object {
      throw const AppFailure(AppFailureKind.storage);
    }
  }

  Future<void> write(RateSnapshot snapshot) async {
    try {
      await _preferences.setString(
        key,
        jsonEncode({
          'schemaVersion': schemaVersion,
          'snapshot': snapshot.toJson(),
        }),
      );
    } on Object {
      throw const AppFailure(AppFailureKind.storage);
    }
  }
}
