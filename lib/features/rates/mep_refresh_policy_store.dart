import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/app_failure.dart';
import 'mep_refresh_policy.dart';

class MepRefreshPolicyStore {
  MepRefreshPolicyStore(this._preferences);

  static const key = 'mep_refresh_policy_v1';
  final SharedPreferencesAsync _preferences;

  Future<MepRefreshPolicy> read() async {
    try {
      final encoded = await _preferences.getString(key);
      if (encoded == null) return const MepRefreshPolicy();
      final data = jsonDecode(encoded);
      if (data is! Map<String, dynamic> ||
          data['schemaVersion'] != 1 ||
          data['policy'] is! Map<String, dynamic>) {
        throw const FormatException('schema');
      }
      return MepRefreshPolicy.fromJson(data['policy'] as Map<String, dynamic>);
    } on Object {
      throw const AppFailure(AppFailureKind.storage);
    }
  }

  Future<void> write(MepRefreshPolicy value) async {
    try {
      await _preferences.setString(
        key,
        jsonEncode({'schemaVersion': 1, 'policy': value.toJson()}),
      );
    } on Object {
      throw const AppFailure(AppFailureKind.storage);
    }
  }
}
