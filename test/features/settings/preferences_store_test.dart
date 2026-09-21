import 'package:coinconversion/features/settings/preferences_store.dart';
import 'package:coinconversion/features/settings/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('persiste orden, par, referencia y tema', () async {
    final store = PreferencesStore(SharedPreferencesAsync());
    final preferences = UserPreferences(
      favoriteCodes: const ['PEN', 'USD', 'ARS'],
      referenceCode: 'PEN',
      converterFromCode: 'ARS',
      converterToCode: 'EUR',
      themeMode: ThemeMode.dark,
    );

    await store.write(preferences);
    final restored = await store.read();

    expect(restored.favoriteCodes, ['PEN', 'USD', 'ARS']);
    expect(restored.referenceCode, 'PEN');
    expect(restored.converterFromCode, 'ARS');
    expect(restored.converterToCode, 'EUR');
    expect(restored.themeMode, ThemeMode.dark);
  });

  test('repara campos inválidos y conserva favoritos vacíos', () {
    final repaired = UserPreferences.fromJson({
      'favoriteCodes': <String>[],
      'referenceCode': 'XXX',
      'converterFromCode': 'bad',
      'converterToCode': 'EUR',
      'themeMode': 'unknown',
    });

    expect(repaired.favoriteCodes, isEmpty);
    expect(repaired.referenceCode, 'USD');
    expect(repaired.converterFromCode, 'USD');
    expect(repaired.converterToCode, 'EUR');
    expect(repaired.themeMode, ThemeMode.system);
  });

  test('deduplica favoritos y descarta códigos desconocidos', () {
    final repaired = UserPreferences(
      favoriteCodes: const ['USD', 'usd', 'XXX', 'PEN'],
      referenceCode: 'USD',
      converterFromCode: 'USD',
      converterToCode: 'PEN',
      themeMode: ThemeMode.system,
    );

    expect(repaired.favoriteCodes, ['USD', 'PEN']);
  });
}
