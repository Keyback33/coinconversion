import 'package:coinconversion/features/rates/rate_snapshot.dart';
import 'package:coinconversion/features/rates/rates_cache.dart';
import 'package:coinconversion/shared/app_failure.dart';
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

  test('hace round-trip del snapshot completo', () async {
    final cache = RatesCache(SharedPreferencesAsync());
    final snapshot = _snapshot();

    await cache.write(snapshot);
    final restored = await cache.read();

    expect(restored?.providerId, snapshot.providerId);
    expect(restored?.rates, snapshot.rates);
    expect(restored?.quotedAtUtc, snapshot.quotedAtUtc);
    expect(restored?.fetchedAtUtc, snapshot.fetchedAtUtc);
  });

  test('cache corrupto se informa como error de almacenamiento', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({RatesCache.key: '{invalid'});
    final cache = RatesCache(SharedPreferencesAsync());

    await expectLater(
      cache.read(),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.kind,
          'kind',
          AppFailureKind.storage,
        ),
      ),
    );
  });
}

RateSnapshot _snapshot() => RateSnapshot(
  baseCode: 'USD',
  rates: const {
    'USD': 1,
    'ARS': 1450,
    'PEN': 3.745,
    'EUR': 0.92,
    'BRL': 5.1,
    'CLP': 930,
    'UYU': 39.2,
  },
  providerId: 'exchange_rate_api',
  quotedAtUtc: DateTime.utc(2026, 9, 21, 12),
  fetchedAtUtc: DateTime.utc(2026, 9, 21, 12, 5),
);
