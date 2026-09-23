import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'features/rates/exchange_rate_api_client.dart';
import 'features/rates/exchange_rate_repository.dart';
import 'features/rates/exchange_rate_source.dart';
import 'features/rates/argentina_datos_mep_client.dart';
import 'features/rates/dolar_api_client.dart';
import 'features/rates/mep_cache.dart';
import 'features/rates/mep_rate_repository.dart';
import 'features/rates/mep_rate_source.dart';
import 'features/rates/mep_refresh_policy_store.dart';
import 'features/rates/frankfurter_api_client.dart';
import 'features/rates/rates_cache.dart';
import 'features/rates/rates_controller.dart';
import 'features/rates/rates_state.dart';
import 'features/rates/refresh_policy_store.dart';
import 'features/rates/rates_refresh_coordinator.dart';
import 'features/settings/preferences_controller.dart';
import 'features/settings/preferences_store.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final sharedPreferencesProvider = Provider<SharedPreferencesAsync>(
  (ref) => SharedPreferencesAsync(),
);

final primaryRateSourceProvider = Provider<ExchangeRateSource>(
  (ref) => ExchangeRateApiClient(client: ref.watch(httpClientProvider)),
);

final fallbackRateSourceProvider = Provider<ExchangeRateSource>(
  (ref) => FrankfurterApiClient(client: ref.watch(httpClientProvider)),
);

final ratesCacheProvider = Provider<RatesCache>(
  (ref) => RatesCache(ref.watch(sharedPreferencesProvider)),
);

final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => PreferencesStore(ref.watch(sharedPreferencesProvider)),
);

final refreshPolicyStoreProvider = Provider<RefreshPolicyStore>(
  (ref) => RefreshPolicyStore(ref.watch(sharedPreferencesProvider)),
);

final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>(
  (ref) => ExchangeRateRepository(
    primary: ref.watch(primaryRateSourceProvider),
    fallback: ref.watch(fallbackRateSourceProvider),
    cache: ref.watch(ratesCacheProvider),
    policyStore: ref.watch(refreshPolicyStoreProvider),
  ),
);

final primaryMepSourceProvider = Provider<MepRateSource>(
  (ref) => DolarApiClient(client: ref.watch(httpClientProvider)),
);

final fallbackMepSourceProvider = Provider<MepRateSource>(
  (ref) => ArgentinaDatosMepClient(client: ref.watch(httpClientProvider)),
);

final mepCacheProvider = Provider<MepCache>(
  (ref) => MepCache(ref.watch(sharedPreferencesProvider)),
);

final mepPolicyStoreProvider = Provider<MepRefreshPolicyStore>(
  (ref) => MepRefreshPolicyStore(ref.watch(sharedPreferencesProvider)),
);

final mepRateRepositoryProvider = Provider<MepRateRepository>(
  (ref) => MepRateRepository(
    primary: ref.watch(primaryMepSourceProvider),
    fallback: ref.watch(fallbackMepSourceProvider),
    cache: ref.watch(mepCacheProvider),
    policyStore: ref.watch(mepPolicyStoreProvider),
  ),
);

final ratesRefreshCoordinatorProvider = Provider<RatesRefreshCoordinator>(
  (ref) => RatesRefreshCoordinator(
    general: ref.watch(exchangeRateRepositoryProvider),
    mep: ref.watch(mepRateRepositoryProvider),
    policyStore: ref.watch(refreshPolicyStoreProvider),
  ),
);

final ratesControllerProvider = NotifierProvider<RatesController, RatesState>(
  RatesController.new,
);

final preferencesControllerProvider =
    NotifierProvider<PreferencesController, PreferencesState>(
      PreferencesController.new,
    );
