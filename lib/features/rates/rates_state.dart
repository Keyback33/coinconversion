import '../../shared/app_failure.dart';
import 'exchange_rate_repository.dart';
import 'rate_snapshot.dart';
import 'mep_quote.dart';
import 'conversion_rates.dart';

enum RatesSource { none, cache, network }

class RatesState {
  const RatesState({
    this.snapshot,
    this.mep,
    this.isLoadingCache = true,
    this.isRefreshing = false,
    this.source = RatesSource.none,
    this.refreshFailure,
    this.cacheReadFailed = false,
    this.cacheWriteFailed = false,
    this.attemptingProviderId,
    this.lastRefreshOutcome,
    this.manualRefreshAvailableAtUtc,
    this.mepSource = RatesSource.none,
    this.mepRefreshFailure,
    this.mepCacheReadFailed = false,
    this.mepCacheWriteFailed = false,
    this.mepPolicyWriteFailed = false,
  });

  final RateSnapshot? snapshot;
  final MepQuote? mep;
  ConversionRates get conversionRates =>
      ConversionRates(snapshot: snapshot, mep: mep);
  final bool isLoadingCache;
  final bool isRefreshing;
  final RatesSource source;
  final AppFailure? refreshFailure;
  final bool cacheReadFailed;
  final bool cacheWriteFailed;
  final String? attemptingProviderId;
  final RefreshOutcome? lastRefreshOutcome;
  final DateTime? manualRefreshAvailableAtUtc;
  final RatesSource mepSource;
  final AppFailure? mepRefreshFailure;
  final bool mepCacheReadFailed;
  final bool mepCacheWriteFailed;
  final bool mepPolicyWriteFailed;

  RatesState copyWith({
    RateSnapshot? snapshot,
    MepQuote? mep,
    bool? isLoadingCache,
    bool? isRefreshing,
    RatesSource? source,
    AppFailure? refreshFailure,
    bool clearRefreshFailure = false,
    bool? cacheReadFailed,
    bool? cacheWriteFailed,
    String? attemptingProviderId,
    bool clearAttemptingProvider = false,
    RefreshOutcome? lastRefreshOutcome,
    DateTime? manualRefreshAvailableAtUtc,
    bool clearManualRefreshAvailableAt = false,
    RatesSource? mepSource,
    AppFailure? mepRefreshFailure,
    bool clearMepRefreshFailure = false,
    bool? mepCacheReadFailed,
    bool? mepCacheWriteFailed,
    bool? mepPolicyWriteFailed,
  }) {
    return RatesState(
      snapshot: snapshot ?? this.snapshot,
      mep: mep ?? this.mep,
      isLoadingCache: isLoadingCache ?? this.isLoadingCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      source: source ?? this.source,
      refreshFailure: clearRefreshFailure
          ? null
          : refreshFailure ?? this.refreshFailure,
      cacheReadFailed: cacheReadFailed ?? this.cacheReadFailed,
      cacheWriteFailed: cacheWriteFailed ?? this.cacheWriteFailed,
      attemptingProviderId: clearAttemptingProvider
          ? null
          : attemptingProviderId ?? this.attemptingProviderId,
      lastRefreshOutcome: lastRefreshOutcome ?? this.lastRefreshOutcome,
      manualRefreshAvailableAtUtc: clearManualRefreshAvailableAt
          ? null
          : manualRefreshAvailableAtUtc ?? this.manualRefreshAvailableAtUtc,
      mepSource: mepSource ?? this.mepSource,
      mepRefreshFailure: clearMepRefreshFailure
          ? null
          : mepRefreshFailure ?? this.mepRefreshFailure,
      mepCacheReadFailed: mepCacheReadFailed ?? this.mepCacheReadFailed,
      mepCacheWriteFailed: mepCacheWriteFailed ?? this.mepCacheWriteFailed,
      mepPolicyWriteFailed: mepPolicyWriteFailed ?? this.mepPolicyWriteFailed,
    );
  }
}
