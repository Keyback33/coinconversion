import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../shared/app_failure.dart';
import 'exchange_rate_repository.dart';
import 'rates_state.dart';

class RatesController extends Notifier<RatesState> {
  bool _initialized = false;

  @override
  RatesState build() => const RatesState();

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    try {
      final snapshot = await ref
          .read(exchangeRateRepositoryProvider)
          .readCached();
      state = state.copyWith(
        snapshot: snapshot,
        isLoadingCache: false,
        source: snapshot == null ? RatesSource.none : RatesSource.cache,
      );
    } on AppFailure {
      state = state.copyWith(isLoadingCache: false, cacheReadFailed: true);
    }
    await refresh(RefreshTrigger.automatic);
  }

  Future<void> refresh(RefreshTrigger trigger) async {
    if (state.isRefreshing) {
      return;
    }
    state = state.copyWith(
      isRefreshing: true,
      attemptingProviderId: 'exchange_rate_api',
      clearRefreshFailure: true,
      cacheWriteFailed: false,
    );
    try {
      final result = await ref
          .read(exchangeRateRepositoryProvider)
          .refresh(trigger);
      state = state.copyWith(
        snapshot: result.snapshot,
        isRefreshing: false,
        source: result.usedNetwork ? RatesSource.network : state.source,
        refreshFailure: result.failure,
        cacheWriteFailed: !result.persisted,
        lastRefreshOutcome: result.outcome,
        clearAttemptingProvider: true,
      );
    } on AppFailure catch (failure) {
      state = state.copyWith(
        isRefreshing: false,
        refreshFailure: failure,
        clearAttemptingProvider: true,
      );
    }
  }
}
