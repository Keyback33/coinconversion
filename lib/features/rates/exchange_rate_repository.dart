import '../../shared/app_failure.dart';
import 'exchange_rate_source.dart';
import 'rate_snapshot.dart';
import 'rates_cache.dart';
import 'refresh_policy.dart';
import 'refresh_policy_store.dart';

enum RefreshTrigger { automatic, manual }

enum RefreshOutcome { updated, confirmed, noNewer, cacheKept, limited }

class RefreshResult {
  const RefreshResult({
    required this.snapshot,
    required this.persisted,
    required this.outcome,
    required this.usedNetwork,
    this.failure,
  });

  final RateSnapshot snapshot;
  final bool persisted;
  final RefreshOutcome outcome;
  final bool usedNetwork;
  final AppFailure? failure;
}

class ExchangeRateRepository {
  ExchangeRateRepository({
    required ExchangeRateSource primary,
    required ExchangeRateSource fallback,
    required RatesCache cache,
    required RefreshPolicyStore policyStore,
    DateTime Function()? nowUtc,
  }) : _primary = primary,
       _fallback = fallback,
       _cache = cache,
       _policyStore = policyStore,
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  static const automaticInterval = Duration(hours: 1);
  static const manualDebounce = Duration(seconds: 60);
  static const fallbackInterval = Duration(minutes: 5);
  static const primaryRateLimitCooldown = Duration(minutes: 20);
  static const fallbackDailyLimit = 30;

  final ExchangeRateSource _primary;
  final ExchangeRateSource _fallback;
  final RatesCache _cache;
  final RefreshPolicyStore _policyStore;
  final DateTime Function() _nowUtc;

  RateSnapshot? _current;
  Future<RefreshResult>? _inFlight;

  Future<RateSnapshot?> readCached() async {
    _current = await _cache.read();
    return _current;
  }

  Future<RefreshResult> refresh(RefreshTrigger trigger) {
    final active = _inFlight;
    if (active != null) {
      return active;
    }
    final operation = _refresh(trigger);
    _inFlight = operation;
    return operation.whenComplete(() {
      if (identical(_inFlight, operation)) {
        _inFlight = null;
      }
    });
  }

  Future<RefreshResult> _refresh(RefreshTrigger trigger) async {
    final now = _nowUtc().toUtc();
    var policy = await _readPolicySafely();
    policy = _normalizePolicy(policy, now);

    final triggerTime = trigger == RefreshTrigger.automatic
        ? policy.lastAutomaticAtUtc
        : policy.lastManualAtUtc;
    final triggerInterval = trigger == RefreshTrigger.automatic
        ? automaticInterval
        : manualDebounce;
    if (_withinInterval(triggerTime, now, triggerInterval)) {
      return _limitedResult();
    }

    policy = trigger == RefreshTrigger.automatic
        ? policy.copyWith(lastAutomaticAtUtc: now)
        : policy.copyWith(lastManualAtUtc: now);
    await _writePolicySafely(policy);

    RateSnapshot? primaryCandidate;
    RateSnapshot? fallbackCandidate;
    AppFailure? lastFailure;
    var requestCount = 0;

    if (!_isBlocked(policy.primary, now)) {
      requestCount++;
      policy = policy.copyWith(
        primary: policy.primary.copyWith(lastAttemptAtUtc: now),
      );
      await _writePolicySafely(policy);
      try {
        primaryCandidate = await _primary.fetchLatest();
        policy = policy.copyWith(
          primary: policy.primary.copyWith(clearBlock: true),
        );
      } on AppFailure catch (failure) {
        lastFailure = failure;
        if (failure.kind == AppFailureKind.rateLimited) {
          policy = policy.copyWith(
            primary: policy.primary.copyWith(
              blockedUntilUtc: now.add(
                failure.retryAfter ?? primaryRateLimitCooldown,
              ),
            ),
          );
        }
      }
      await _writePolicySafely(policy);
    }

    final needsFallback =
        primaryCandidate == null ||
        (_current != null &&
            !primaryCandidate.quotedAtUtc.isAfter(_current!.quotedAtUtc)) ||
        now.difference(primaryCandidate.quotedAtUtc) >= automaticInterval;

    if (needsFallback && _canAttemptFallback(policy, now)) {
      requestCount++;
      policy = policy.copyWith(
        fallback: policy.fallback.copyWith(lastAttemptAtUtc: now),
        fallbackBudgetDayUtc: _dayUtc(now),
        fallbackAttemptsToday: policy.fallbackAttemptsToday + 1,
      );
      await _writePolicySafely(policy);
      try {
        fallbackCandidate = await _fallback.fetchLatest();
        policy = policy.copyWith(
          fallback: policy.fallback.copyWith(clearBlock: true),
        );
      } on AppFailure catch (failure) {
        lastFailure = failure;
        if (failure.kind == AppFailureKind.rateLimited ||
            failure.kind == AppFailureKind.authentication ||
            failure.kind == AppFailureKind.missingConfiguration) {
          policy = policy.copyWith(
            fallback: policy.fallback.copyWith(
              blockedUntilUtc: failure.retryAfter == null
                  ? _dayUtc(now).add(const Duration(days: 1))
                  : now.add(failure.retryAfter!),
            ),
          );
        }
      }
      await _writePolicySafely(policy);
    }

    var selected = _current;
    var acceptedNetwork = false;
    for (final candidate in [primaryCandidate, fallbackCandidate]) {
      if (candidate == null) {
        continue;
      }
      final next = _select(selected, candidate);
      if (!identical(next, selected)) {
        selected = next;
        acceptedNetwork = true;
      }
    }

    if (selected == null) {
      throw lastFailure ?? const AppFailure(AppFailureKind.noData);
    }

    var persisted = true;
    if (acceptedNetwork) {
      try {
        await _cache.write(selected);
      } on AppFailure {
        persisted = false;
      }
      final previous = _current;
      _current = selected;
      final outcome =
          previous == null || selected.quotedAtUtc.isAfter(previous.quotedAtUtc)
          ? RefreshOutcome.updated
          : RefreshOutcome.confirmed;
      return RefreshResult(
        snapshot: selected,
        persisted: persisted,
        outcome: outcome,
        usedNetwork: true,
      );
    }

    final hadCandidates = primaryCandidate != null || fallbackCandidate != null;
    return RefreshResult(
      snapshot: selected,
      persisted: true,
      outcome: requestCount == 0
          ? RefreshOutcome.limited
          : hadCandidates
          ? RefreshOutcome.noNewer
          : RefreshOutcome.cacheKept,
      usedNetwork: false,
      failure: lastFailure,
    );
  }

  RefreshResult _limitedResult() {
    final snapshot = _current;
    if (snapshot == null) {
      throw const AppFailure(AppFailureKind.refreshLimited);
    }
    return RefreshResult(
      snapshot: snapshot,
      persisted: true,
      outcome: RefreshOutcome.limited,
      usedNetwork: false,
    );
  }

  RateSnapshot _select(RateSnapshot? current, RateSnapshot candidate) {
    if (current == null ||
        candidate.quotedAtUtc.isAfter(current.quotedAtUtc) ||
        (candidate.quotedAtUtc.isAtSameMomentAs(current.quotedAtUtc) &&
            candidate.providerId == current.providerId)) {
      return candidate;
    }
    return current;
  }

  bool _canAttemptFallback(RefreshPolicy policy, DateTime now) {
    return !_isBlocked(policy.fallback, now) &&
        !_withinInterval(
          policy.fallback.lastAttemptAtUtc,
          now,
          fallbackInterval,
        ) &&
        policy.fallbackAttemptsToday < fallbackDailyLimit;
  }

  bool _isBlocked(ProviderRefreshRecord record, DateTime now) {
    final blockedUntil = record.blockedUntilUtc;
    return blockedUntil != null && blockedUntil.isAfter(now);
  }

  bool _withinInterval(DateTime? previous, DateTime now, Duration interval) {
    if (previous == null || previous.isAfter(now)) {
      return false;
    }
    return now.difference(previous) < interval;
  }

  RefreshPolicy _normalizePolicy(RefreshPolicy policy, DateTime now) {
    if (policy.fallbackBudgetDayUtc == null ||
        !_dayUtc(policy.fallbackBudgetDayUtc!).isAtSameMomentAs(_dayUtc(now))) {
      return policy.copyWith(
        fallbackBudgetDayUtc: _dayUtc(now),
        fallbackAttemptsToday: 0,
      );
    }
    return policy;
  }

  DateTime _dayUtc(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);

  Future<RefreshPolicy> _readPolicySafely() async {
    try {
      return await _policyStore.read();
    } on AppFailure {
      return const RefreshPolicy();
    }
  }

  Future<void> _writePolicySafely(RefreshPolicy policy) async {
    try {
      await _policyStore.write(policy);
    } on AppFailure {
      return;
    }
  }
}
