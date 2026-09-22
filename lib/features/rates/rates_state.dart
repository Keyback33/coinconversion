import '../../shared/app_failure.dart';
import 'exchange_rate_repository.dart';
import 'rate_snapshot.dart';

enum RatesSource { none, cache, network }

class RatesState {
  const RatesState({
    this.snapshot,
    this.isLoadingCache = true,
    this.isRefreshing = false,
    this.source = RatesSource.none,
    this.refreshFailure,
    this.cacheReadFailed = false,
    this.cacheWriteFailed = false,
    this.attemptingProviderId,
    this.lastRefreshOutcome,
    this.manualRefreshAvailableAtUtc,
  });

  final RateSnapshot? snapshot;
  final bool isLoadingCache;
  final bool isRefreshing;
  final RatesSource source;
  final AppFailure? refreshFailure;
  final bool cacheReadFailed;
  final bool cacheWriteFailed;
  final String? attemptingProviderId;
  final RefreshOutcome? lastRefreshOutcome;
  final DateTime? manualRefreshAvailableAtUtc;

  RatesState copyWith({
    RateSnapshot? snapshot,
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
  }) {
    return RatesState(
      snapshot: snapshot ?? this.snapshot,
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
    );
  }
}
