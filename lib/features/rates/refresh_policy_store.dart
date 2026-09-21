import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/app_failure.dart';
import 'refresh_policy.dart';

class RefreshPolicyStore {
  RefreshPolicyStore(this._preferences);

  static const key = 'refresh_policy_v1';
  static const schemaVersion = 1;

  final SharedPreferencesAsync _preferences;

  Future<RefreshPolicy> read() async {
    try {
      final encoded = await _preferences.getString(key);
      if (encoded == null) {
        return const RefreshPolicy();
      }
      final json = jsonDecode(encoded);
      if (json is! Map<String, dynamic> ||
          json['schemaVersion'] != schemaVersion ||
          json['policy'] is! Map<String, dynamic>) {
        throw const FormatException('schema');
      }
      return RefreshPolicy.fromJson(json['policy'] as Map<String, dynamic>);
    } on Object {
      throw const AppFailure(AppFailureKind.storage);
    }
  }

  Future<void> write(RefreshPolicy value) async {
    try {
      await _preferences.setString(
        key,
        jsonEncode({'schemaVersion': schemaVersion, 'policy': value.toJson()}),
      );
    } on Object {
      throw const AppFailure(AppFailureKind.storage);
    }
  }
}
