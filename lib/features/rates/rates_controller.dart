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
    if (_initialized) return;
    _initialized = true;
    final general = ref.read(exchangeRateRepositoryProvider);
    final mep = ref.read(mepRateRepositoryProvider);
    final coordinator = ref.read(ratesRefreshCoordinatorProvider);
    try {
      final snapshot = await general.readCached();
      state = state.copyWith(
        snapshot: snapshot,
        source: snapshot == null ? RatesSource.none : RatesSource.cache,
      );
    } on AppFailure {
      state = state.copyWith(cacheReadFailed: true);
    }
    try {
      final quote = await mep.readCached();
      state = state.copyWith(
        mep: quote,
        mepSource: quote == null ? RatesSource.none : RatesSource.cache,
      );
    } on AppFailure {
      state = state.copyWith(mepCacheReadFailed: true);
    }
    final available = await coordinator.readManualRefreshAvailableAtUtc();
    state = state.copyWith(
      isLoadingCache: false,
      manualRefreshAvailableAtUtc: available,
      clearManualRefreshAvailableAt: available == null,
    );
    await refresh(RefreshTrigger.automatic);
  }

  Future<void> refresh(RefreshTrigger trigger) async {
    if (state.isRefreshing) return;
    state = state.copyWith(
      isRefreshing: true,
      clearRefreshFailure: true,
      clearMepRefreshFailure: true,
      cacheWriteFailed: false,
      mepCacheWriteFailed: false,
      mepPolicyWriteFailed: false,
    );
    try {
      final result = await ref
          .read(ratesRefreshCoordinatorProvider)
          .refresh(
            trigger,
            onGeneral: (data, failure) {
              state = state.copyWith(
                snapshot: data?.snapshot,
                source: data?.usedNetwork == true
                    ? RatesSource.network
                    : state.source,
                refreshFailure: failure ?? data?.failure,
                cacheWriteFailed: data != null && !data.persisted,
                lastRefreshOutcome: data?.outcome,
              );
            },
            onMep: (data, failure) {
              state = state.copyWith(
                mep: data?.quote,
                mepSource: data?.usedNetwork == true
                    ? RatesSource.network
                    : state.mepSource,
                mepRefreshFailure: failure ?? data?.failure,
                mepCacheWriteFailed: data != null && !data.persisted,
                mepPolicyWriteFailed: data != null && !data.policyPersisted,
              );
            },
          );
      state = state.copyWith(
        isRefreshing: false,
        lastRefreshOutcome: result.limited
            ? RefreshOutcome.limited
            : state.lastRefreshOutcome,
        mepPolicyWriteFailed:
            !result.policyPersisted || state.mepPolicyWriteFailed,
        manualRefreshAvailableAtUtc: result.manualRefreshAvailableAtUtc,
        clearManualRefreshAvailableAt:
            result.manualRefreshAvailableAtUtc == null,
      );
    } on AppFailure catch (failure) {
      state = state.copyWith(isRefreshing: false, refreshFailure: failure);
    }
  }
}
