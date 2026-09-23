import 'dart:async';

import 'package:coinconversion/features/rates/exchange_rate_repository.dart';
import 'package:coinconversion/features/rates/exchange_rate_source.dart';
import 'package:coinconversion/features/rates/rate_snapshot.dart';
import 'package:coinconversion/features/rates/rates_cache.dart';
import 'package:coinconversion/features/rates/refresh_policy.dart';
import 'package:coinconversion/features/rates/refresh_policy_store.dart';
import 'package:coinconversion/shared/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  final now = DateTime.utc(2026, 9, 21, 12);

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('principal vigente evita consultar fallback', () async {
    final primary = _FakeSource(
      'exchange_rate_api',
      () async => _snapshot(
        'exchange_rate_api',
        now.subtract(const Duration(minutes: 10)),
      ),
    );
    final fallback = _FakeSource(
      'open_exchange_rates',
      () async => _snapshot('open_exchange_rates', now),
    );
    final repository = _repository(primary, fallback, now: now);

    final result = await repository.refresh(RefreshTrigger.manual);

    expect(result.snapshot.providerId, 'exchange_rate_api');
    expect(result.outcome, RefreshOutcome.updated);
    expect(primary.calls, 1);
    expect(fallback.calls, 0);
  });

  test(
    'principal sin novedad activa fallback y selecciona el más nuevo',
    () async {
      final cached = _snapshot(
        'exchange_rate_api',
        now.subtract(const Duration(hours: 2)),
      );
      final cache = _MemoryRatesCache()..value = cached;
      final primary = _FakeSource('exchange_rate_api', () async => cached);
      final fallbackSnapshot = _snapshot('open_exchange_rates', now);
      final fallback = _FakeSource(
        'open_exchange_rates',
        () async => fallbackSnapshot,
      );
      final repository = _repository(primary, fallback, now: now, cache: cache);
      await repository.readCached();

      final result = await repository.refresh(RefreshTrigger.manual);

      expect(result.snapshot, same(fallbackSnapshot));
      expect(result.outcome, RefreshOutcome.updated);
      expect(cache.value, same(fallbackSnapshot));
      expect(primary.calls, 1);
      expect(fallback.calls, 1);
    },
  );

  test('fallas de ambos providers conservan cache y sus fechas', () async {
    final cached = _snapshot(
      'exchange_rate_api',
      now.subtract(const Duration(days: 2)),
    );
    final cache = _MemoryRatesCache()..value = cached;
    final primary = _FakeSource(
      'exchange_rate_api',
      () async => throw const AppFailure(AppFailureKind.transport),
    );
    final fallback = _FakeSource(
      'open_exchange_rates',
      () async => throw const AppFailure(AppFailureKind.timeout),
    );
    final repository = _repository(primary, fallback, now: now, cache: cache);
    await repository.readCached();

    final result = await repository.refresh(RefreshTrigger.manual);

    expect(result.snapshot, same(cached));
    expect(result.outcome, RefreshOutcome.cacheKept);
    expect(result.failure?.kind, AppFailureKind.timeout);
    expect(result.snapshot.fetchedAtUtc, cached.fetchedAtUtc);
  });

  test('llamadas concurrentes comparten una sola cadena', () async {
    final completer = Completer<RateSnapshot>();
    final primary = _FakeSource('exchange_rate_api', () => completer.future);
    final fallback = _FakeSource(
      'open_exchange_rates',
      () async => _snapshot('open_exchange_rates', now),
    );
    final repository = _repository(primary, fallback, now: now);

    final first = repository.refresh(RefreshTrigger.manual);
    final second = repository.refresh(RefreshTrigger.manual);
    completer.complete(
      _snapshot('exchange_rate_api', now.subtract(const Duration(minutes: 10))),
    );

    final results = await Future.wait([first, second]);
    expect(primary.calls, 1);
    expect(results[0].snapshot, same(results[1].snapshot));
  });

  test('fallo al persistir mantiene el snapshot de sesión', () async {
    final cache = _MemoryRatesCache()..failWrite = true;
    final snapshot = _snapshot(
      'exchange_rate_api',
      now.subtract(const Duration(minutes: 10)),
    );
    final repository = _repository(
      _FakeSource('exchange_rate_api', () async => snapshot),
      _FakeSource('open_exchange_rates', () async => snapshot),
      now: now,
      cache: cache,
    );

    final result = await repository.refresh(RefreshTrigger.manual);

    expect(result.snapshot, same(snapshot));
    expect(result.persisted, isFalse);
  });

  test('refresh manual usa ciclos fijos de una hora', () async {
    var current = now;
    final primary = _FakeSource(
      'exchange_rate_api',
      () async => _snapshot(
        'exchange_rate_api',
        current.subtract(const Duration(minutes: 10)),
      ),
    );
    final fallback = _FakeSource(
      'open_exchange_rates',
      () async => _snapshot('open_exchange_rates', current),
    );
    final repository = _repository(
      primary,
      fallback,
      now: now,
      nowUtc: () => current,
    );

    final first = await repository.refresh(RefreshTrigger.manual);
    expect(
      first.manualRefreshAvailableAtUtc,
      now.add(const Duration(hours: 1)),
    );

    current = now.add(const Duration(minutes: 59));
    final limited = await repository.refresh(RefreshTrigger.manual);
    expect(limited.outcome, RefreshOutcome.limited);
    expect(
      limited.manualRefreshAvailableAtUtc,
      now.add(const Duration(hours: 1)),
    );
    expect(primary.calls, 1);

    current = now.add(const Duration(hours: 1));
    final second = await repository.refresh(RefreshTrigger.manual);
    expect(second.outcome, RefreshOutcome.updated);
    expect(
      second.manualRefreshAvailableAtUtc,
      now.add(const Duration(hours: 2)),
    );
    expect(primary.calls, 2);
  });

  test('refresh automático no modifica el cooldown manual', () async {
    var current = now;
    final primary = _FakeSource(
      'exchange_rate_api',
      () async => _snapshot(
        'exchange_rate_api',
        current.subtract(const Duration(minutes: 10)),
      ),
    );
    final repository = _repository(
      primary,
      _FakeSource(
        'open_exchange_rates',
        () async => _snapshot('open_exchange_rates', current),
      ),
      now: now,
      nowUtc: () => current,
    );

    await repository.refresh(RefreshTrigger.manual);
    current = now.add(const Duration(minutes: 30));
    final automatic = await repository.refresh(RefreshTrigger.automatic);

    expect(primary.calls, 2);
    expect(
      automatic.manualRefreshAvailableAtUtc,
      now.add(const Duration(hours: 1)),
    );

    current = now.add(const Duration(minutes: 45));
    final manual = await repository.refresh(RefreshTrigger.manual);
    expect(manual.outcome, RefreshOutcome.limited);
    expect(primary.calls, 2);
  });

  test('cooldown manual se recupera desde la política persistida', () async {
    final policyStore = _MemoryPolicyStore();
    final primary = _FakeSource(
      'exchange_rate_api',
      () async => _snapshot(
        'exchange_rate_api',
        now.subtract(const Duration(minutes: 10)),
      ),
    );
    final fallback = _FakeSource(
      'open_exchange_rates',
      () async => _snapshot('open_exchange_rates', now),
    );
    final repository = _repository(
      primary,
      fallback,
      now: now,
      policyStore: policyStore,
    );
    await repository.refresh(RefreshTrigger.manual);

    final recreated = _repository(
      primary,
      fallback,
      now: now.add(const Duration(minutes: 15)),
      policyStore: policyStore,
    );

    expect(
      await recreated.readManualRefreshAvailableAtUtc(),
      now.add(const Duration(hours: 1)),
    );
  });

  test('migra límites OXR sin perder cooldown global ni cache', () async {
    final cached = _snapshot(
      'open_exchange_rates',
      now.subtract(const Duration(days: 2)),
    );
    final cache = _MemoryRatesCache()..value = cached;
    final policyStore = _MemoryPolicyStore()
      ..value = RefreshPolicy(
        lastManualAtUtc: now.subtract(const Duration(minutes: 30)),
        fallback: ProviderRefreshRecord(
          lastAttemptAtUtc: now,
          blockedUntilUtc: now.add(const Duration(days: 1)),
        ),
        fallbackBudgetDayUtc: DateTime.utc(now.year, now.month, now.day),
        fallbackAttemptsToday: 30,
      );
    final fallback = _FakeSource(
      'frankfurter',
      () async => _dailySnapshot(DateTime.utc(2026, 9, 22)),
    );
    final repository = _repository(
      _FakeSource(
        'exchange_rate_api',
        () async => throw const AppFailure(AppFailureKind.transport),
      ),
      fallback,
      now: now,
      cache: cache,
      policyStore: policyStore,
    );
    await repository.readCached();
    final result = await repository.refresh(RefreshTrigger.automatic);
    expect(result.snapshot.providerId, 'frankfurter');
    expect(fallback.calls, 1);
    expect(policyStore.value.fallbackProviderId, 'frankfurter');
    expect(policyStore.value.fallbackAttemptsToday, 1);
    expect(
      policyStore.value.lastManualAtUtc,
      now.subtract(const Duration(minutes: 30)),
    );
  });

  test(
    'fecha conservadora no reemplaza cache intradiario del mismo día',
    () async {
      final cached = _snapshot(
        'exchange_rate_api',
        DateTime.utc(2026, 9, 21, 12),
      );
      final cache = _MemoryRatesCache()..value = cached;
      final repository = _repository(
        _FakeSource('exchange_rate_api', () async => cached),
        _FakeSource(
          'frankfurter',
          () async => _dailySnapshot(DateTime.utc(2026, 9, 21)),
        ),
        now: now,
        cache: cache,
      );
      await repository.readCached();
      final result = await repository.refresh(RefreshTrigger.manual);
      expect(result.snapshot, same(cached));
    },
  );
}

RateSnapshot _dailySnapshot(DateTime day) {
  final rates = {
    'USD': 1.0,
    'ARS': 1450.0,
    'PEN': 3.745,
    'EUR': 0.92,
    'BRL': 5.1,
    'CLP': 930.0,
    'UYU': 39.2,
  };
  return RateSnapshot(
    baseCode: 'USD',
    rates: rates,
    providerId: 'frankfurter',
    quotedAtUtc: day,
    fetchedAtUtc: day.add(const Duration(days: 1)),
    quotedDatesUtc: {for (final code in rates.keys) code: day},
  );
}

ExchangeRateRepository _repository(
  ExchangeRateSource primary,
  ExchangeRateSource fallback, {
  required DateTime now,
  _MemoryRatesCache? cache,
  _MemoryPolicyStore? policyStore,
  DateTime Function()? nowUtc,
}) {
  return ExchangeRateRepository(
    primary: primary,
    fallback: fallback,
    cache: cache ?? _MemoryRatesCache(),
    policyStore: policyStore ?? _MemoryPolicyStore(),
    nowUtc: nowUtc ?? () => now,
  );
}

RateSnapshot _snapshot(String providerId, DateTime quotedAt) {
  return RateSnapshot(
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
    providerId: providerId,
    quotedAtUtc: quotedAt,
    fetchedAtUtc: quotedAt.add(const Duration(minutes: 1)),
  );
}

class _FakeSource implements ExchangeRateSource {
  _FakeSource(this.providerId, this._fetch);

  @override
  final String providerId;
  final Future<RateSnapshot> Function() _fetch;
  int calls = 0;

  @override
  Uri get attributionUri => Uri.https('example.test');

  @override
  Future<RateSnapshot> fetchLatest() {
    calls++;
    return _fetch();
  }
}

class _MemoryRatesCache extends RatesCache {
  _MemoryRatesCache() : super(SharedPreferencesAsync());

  RateSnapshot? value;
  bool failWrite = false;

  @override
  Future<RateSnapshot?> read() async => value;

  @override
  Future<void> write(RateSnapshot snapshot) async {
    if (failWrite) {
      throw const AppFailure(AppFailureKind.storage);
    }
    value = snapshot;
  }
}

class _MemoryPolicyStore extends RefreshPolicyStore {
  _MemoryPolicyStore() : super(SharedPreferencesAsync());

  RefreshPolicy value = const RefreshPolicy();

  @override
  Future<RefreshPolicy> read() async => value;

  @override
  Future<void> write(RefreshPolicy next) async => value = next;
}
