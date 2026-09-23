import 'package:coinconversion/features/rates/exchange_rate_repository.dart';
import 'package:coinconversion/features/rates/exchange_rate_source.dart';
import 'package:coinconversion/features/rates/mep_cache.dart';
import 'package:coinconversion/features/rates/mep_quote.dart';
import 'package:coinconversion/features/rates/mep_rate_repository.dart';
import 'package:coinconversion/features/rates/mep_rate_source.dart';
import 'package:coinconversion/features/rates/mep_refresh_policy_store.dart';
import 'package:coinconversion/features/rates/rate_snapshot.dart';
import 'package:coinconversion/features/rates/rates_cache.dart';
import 'package:coinconversion/features/rates/rates_refresh_coordinator.dart';
import 'package:coinconversion/features/rates/refresh_policy_store.dart';
import 'package:coinconversion/shared/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  test(
    'éxito MEP y fallo general quedan independientes; guard manual se conserva',
    () async {
      final now = DateTime.utc(2026, 9, 22, 21);
      final preferences = SharedPreferencesAsync();
      final general = _GeneralSource();
      final mep = _MepSource(
        MepQuote(
          sellArsPerUsd: 1200,
          providerId: 'dolar_api',
          quotedDate: '2026-09-22',
          precision: MepTimePrecision.instant,
          quotedAtUtc: DateTime.utc(2026, 9, 22, 20),
          fetchedAtUtc: now,
        ),
      );
      final coordinator = RatesRefreshCoordinator(
        general: ExchangeRateRepository(
          primary: general,
          fallback: general,
          cache: RatesCache(preferences),
          policyStore: RefreshPolicyStore(preferences),
          nowUtc: () => now,
        ),
        mep: MepRateRepository(
          primary: mep,
          fallback: mep,
          cache: MepCache(preferences, nowUtc: () => now),
          policyStore: MepRefreshPolicyStore(preferences),
          nowUtc: () => now,
        ),
        policyStore: RefreshPolicyStore(preferences),
        nowUtc: () => now,
      );
      AppFailure? generalFailure;
      MepRefreshResult? mepResult;
      final first = await coordinator.refresh(
        RefreshTrigger.manual,
        onGeneral: (_, failure) => generalFailure = failure,
        onMep: (result, _) => mepResult = result,
      );
      expect(first.limited, isFalse);
      expect(generalFailure?.kind, AppFailureKind.transport);
      expect(mepResult?.quote?.sellArsPerUsd, 1200);
      expect(await MepCache(preferences, nowUtc: () => now).read(), isNotNull);
      final calls = general.calls;
      final mepCalls = mep.calls;
      final second = await coordinator.refresh(
        RefreshTrigger.manual,
        onGeneral: (_, _) => fail('guard manual'),
        onMep: (_, _) => fail('guard manual'),
      );
      expect(second.limited, isTrue);
      expect(general.calls, calls);
      expect(mep.calls, mepCalls);
      expect(
        (await RefreshPolicyStore(preferences).read()).lastManualAtUtc,
        now,
      );
    },
  );
}

class _GeneralSource implements ExchangeRateSource {
  int calls = 0;
  @override
  String get providerId => 'fixture';
  @override
  Uri get attributionUri => Uri.https('example.test');
  @override
  Future<RateSnapshot> fetchLatest() async {
    calls++;
    throw const AppFailure(AppFailureKind.transport);
  }
}

class _MepSource implements MepRateSource {
  _MepSource(this.quote);
  final MepQuote quote;
  int calls = 0;
  @override
  String get providerId => 'dolar_api';
  @override
  Future<MepQuote> fetchLatest() async {
    calls++;
    return quote;
  }
}
