import 'package:coinconversion/features/rates/mep_cache.dart';
import 'package:coinconversion/features/rates/mep_quote.dart';
import 'package:coinconversion/features/rates/mep_rate_repository.dart';
import 'package:coinconversion/features/rates/mep_rate_source.dart';
import 'package:coinconversion/features/rates/mep_refresh_policy.dart';
import 'package:coinconversion/features/rates/mep_refresh_policy_store.dart';
import 'package:coinconversion/shared/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 22, 21);
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  test('fallback no desplaza cache intradiario más reciente', () async {
    final preferences = SharedPreferencesAsync();
    final cache = MepCache(preferences, nowUtc: () => now);
    final cached = _quote(
      'dolar_api',
      '2026-09-22',
      DateTime.utc(2026, 9, 22, 20),
      1200,
    );
    await cache.write(cached);
    final primary = _Source(
      'dolar_api',
      _quote('dolar_api', '2026-09-22', DateTime.utc(2026, 9, 22, 19), 1190),
    );
    final fallback = _Source(
      'argentina_datos',
      _quote('argentina_datos', '2026-09-22', null, 1180),
    );
    final repo = MepRateRepository(
      primary: primary,
      fallback: fallback,
      cache: cache,
      policyStore: MepRefreshPolicyStore(preferences),
      nowUtc: () => now,
    );
    await repo.readCached();
    final result = await repo.refresh();
    expect(result.quote!.sellArsPerUsd, 1200);
    expect(fallback.calls, 1);
    expect((await cache.read())!.sellArsPerUsd, 1200);
  });

  test('fallback histórico conserva su precisión y presupuesto', () async {
    final preferences = SharedPreferencesAsync();
    final fallback = _Source(
      'argentina_datos',
      _quote('argentina_datos', '2026-09-22', null, 1200),
    );
    final repo = MepRateRepository(
      primary: _Source('dolar_api', null),
      fallback: fallback,
      cache: MepCache(preferences, nowUtc: () => now),
      policyStore: MepRefreshPolicyStore(preferences),
      nowUtc: () => now,
    );
    final result = await repo.refresh();
    expect(result.quote!.precision, MepTimePrecision.date);
    expect(result.quote!.quotedAtUtc, isNull);
    expect(result.usedNetwork, isTrue);
    final policy = await MepRefreshPolicyStore(preferences).read();
    expect(policy.fallbackAttemptsToday, 1);
    await repo.refresh();
    expect(fallback.calls, 1);
  });

  test(
    'MEP principal sin cambios y reciente evita descargar histórico',
    () async {
      final preferences = SharedPreferencesAsync();
      final cache = MepCache(preferences, nowUtc: () => now);
      final previous = _quote(
        'dolar_api',
        '2026-09-22',
        DateTime.utc(2026, 9, 22, 20),
        1200,
      );
      await cache.write(previous);
      final fallback = _Source('argentina_datos', null);
      final repo = MepRateRepository(
        primary: _Source('dolar_api', previous),
        fallback: fallback,
        cache: cache,
        policyStore: MepRefreshPolicyStore(preferences),
        nowUtc: () => now,
      );
      await repo.readCached();
      final result = await repo.refresh();
      expect(result.quote!.sellArsPerUsd, 1200);
      expect(fallback.calls, 0);
    },
  );

  test('cooldown principal sobrevive reinicio del repository', () async {
    var current = now;
    final preferences = SharedPreferencesAsync();
    final primary = _Source(
      'dolar_api',
      _quote('dolar_api', '2026-09-22', DateTime.utc(2026, 9, 22, 20), 1200),
    );
    MepRateRepository repository() => MepRateRepository(
      primary: primary,
      fallback: _Source('argentina_datos', null),
      cache: MepCache(preferences, nowUtc: () => current),
      policyStore: MepRefreshPolicyStore(preferences),
      nowUtc: () => current,
    );
    await repository().refresh();
    current = current.add(const Duration(minutes: 4));
    await repository().refresh();
    expect(primary.calls, 1);
    current = current.add(const Duration(minutes: 1));
    await repository().refresh();
    expect(primary.calls, 2);
  });

  test('presupuesto histórico agotado bloquea fallback', () async {
    final preferences = SharedPreferencesAsync();
    await MepRefreshPolicyStore(preferences).write(
      MepRefreshPolicy(
        fallbackBudgetDayUtc: DateTime.utc(2026, 9, 22),
        fallbackAttemptsToday: 30,
      ),
    );
    final fallback = _Source(
      'argentina_datos',
      _quote('argentina_datos', '2026-09-22', null, 1200),
    );
    final repo = MepRateRepository(
      primary: _Source('dolar_api', null),
      fallback: fallback,
      cache: MepCache(preferences, nowUtc: () => now),
      policyStore: MepRefreshPolicyStore(preferences),
      nowUtc: () => now,
    );
    final result = await repo.refresh();
    expect(result.quote, isNull);
    expect(fallback.calls, 0);
    expect(
      (await MepRefreshPolicyStore(preferences).read()).fallbackAttemptsToday,
      30,
    );
  });
}

MepQuote _quote(String provider, String day, DateTime? instant, double sell) =>
    MepQuote(
      sellArsPerUsd: sell,
      providerId: provider,
      quotedDate: day,
      precision: instant == null
          ? MepTimePrecision.date
          : MepTimePrecision.instant,
      quotedAtUtc: instant,
      fetchedAtUtc: DateTime.utc(2026, 9, 22, 21),
    );

class _Source implements MepRateSource {
  _Source(this.providerId, this.quote);
  @override
  final String providerId;
  final MepQuote? quote;
  int calls = 0;
  @override
  Future<MepQuote> fetchLatest() async {
    calls++;
    if (quote == null) throw const AppFailure(AppFailureKind.transport);
    return quote!;
  }
}
