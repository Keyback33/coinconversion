import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/app_failure.dart';
import 'user_preferences.dart';

class PreferencesStore {
  PreferencesStore(this._preferences);

  static const key = 'user_preferences_v1';
  static const schemaVersion = 1;

  final SharedPreferencesAsync _preferences;

  Future<UserPreferences> read() async {
    try {
      final encoded = await _preferences.getString(key);
      if (encoded == null) {
        return UserPreferences.defaults;
      }
      final json = jsonDecode(encoded);
      if (json is! Map<String, dynamic> ||
          json['schemaVersion'] != schemaVersion ||
          json['preferences'] is! Map<String, dynamic>) {
        throw const FormatException('schema');
      }
      return UserPreferences.fromJson(
        json['preferences'] as Map<String, dynamic>,
      );
    } on Object {
      throw const AppFailure(AppFailureKind.storage);
    }
  }

  Future<void> write(UserPreferences value) async {
    try {
      await _preferences.setString(
        key,
        jsonEncode({
          'schemaVersion': schemaVersion,
          'preferences': value.toJson(),
        }),
      );
    } on Object {
      throw const AppFailure(AppFailureKind.storage);
    }
  }
}
