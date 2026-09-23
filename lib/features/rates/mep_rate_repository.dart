import '../../shared/app_failure.dart';
import 'mep_cache.dart';
import 'mep_quote.dart';
import 'mep_rate_source.dart';
import 'mep_refresh_policy.dart';
import 'mep_refresh_policy_store.dart';
import 'refresh_policy.dart';

class MepRefreshResult {
  const MepRefreshResult({
    required this.quote,
    required this.usedNetwork,
    required this.persisted,
    this.failure,
    this.policyPersisted = true,
  });
  final MepQuote? quote;
  final bool usedNetwork;
  final bool persisted;
  final AppFailure? failure;
  final bool policyPersisted;
}

class MepRateRepository {
  MepRateRepository({
    required MepRateSource primary,
    required MepRateSource fallback,
    required MepCache cache,
    required MepRefreshPolicyStore policyStore,
    DateTime Function()? nowUtc,
  }) : _primary = primary,
       _fallback = fallback,
       _cache = cache,
       _policyStore = policyStore,
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  final MepRateSource _primary;
  final MepRateSource _fallback;
  final MepCache _cache;
  final MepRefreshPolicyStore _policyStore;
  final DateTime Function() _nowUtc;
  MepQuote? _current;
  MepRefreshPolicy? _policy;
  Future<MepRefreshResult>? _inFlight;

  Future<MepQuote?> readCached() async {
    _current = await _cache.read();
    return _current;
  }

  Future<MepRefreshResult> refresh() {
    final active = _inFlight;
    if (active != null) return active;
    final operation = _refresh();
    _inFlight = operation;
    return operation.whenComplete(() {
      if (identical(_inFlight, operation)) _inFlight = null;
    });
  }

  Future<MepRefreshResult> _refresh() async {
    final now = _nowUtc().toUtc();
    var policyPersisted = true;
    MepRefreshPolicy policy;
    try {
      policy = _policy ?? await _policyStore.read();
    } on AppFailure {
      policy = _policy ?? const MepRefreshPolicy();
      policyPersisted = false;
    }
    final day = DateTime.utc(now.year, now.month, now.day);
    if (policy.fallbackBudgetDayUtc != day) {
      policy = policy.copyWith(
        fallbackBudgetDayUtc: day,
        fallbackAttemptsToday: 0,
      );
    }
    Future<void> save() async {
      _policy = policy;
      try {
        await _policyStore.write(policy);
      } on AppFailure {
        policyPersisted = false;
      }
    }

    MepQuote? primaryCandidate;
    MepQuote? fallbackCandidate;
    AppFailure? failure;
    var attempted = false;
    if (_canAttempt(policy.primary, now)) {
      attempted = true;
      policy = policy.copyWith(
        primary: policy.primary.copyWith(lastAttemptAtUtc: now),
      );
      await save();
      try {
        primaryCandidate = await _primary.fetchLatest();
        policy = policy.copyWith(
          primary: policy.primary.copyWith(clearBlock: true),
        );
      } on AppFailure catch (error) {
        failure = error;
        policy = policy.copyWith(
          primary: policy.primary.copyWith(
            blockedUntilUtc: _blockUntil(error, now),
          ),
        );
      }
      await save();
    }
    final needsFallback =
        primaryCandidate == null ||
        (_current != null &&
            primaryCandidate.compareFreshness(_current!) < 0) ||
        primaryCandidate.isStaleAt(now);
    if (needsFallback &&
        policy.fallbackAttemptsToday < 30 &&
        _canAttempt(policy.fallback, now)) {
      attempted = true;
      policy = policy.copyWith(
        fallback: policy.fallback.copyWith(lastAttemptAtUtc: now),
        fallbackAttemptsToday: policy.fallbackAttemptsToday + 1,
      );
      await save();
      try {
        fallbackCandidate = await _fallback.fetchLatest();
        policy = policy.copyWith(
          fallback: policy.fallback.copyWith(clearBlock: true),
        );
      } on AppFailure catch (error) {
        failure = error;
        policy = policy.copyWith(
          fallback: policy.fallback.copyWith(
            blockedUntilUtc: _blockUntil(error, now),
          ),
        );
      }
      await save();
    }
    var selected = _current;
    var accepted = false;
    for (final candidate in [primaryCandidate, fallbackCandidate]) {
      if (candidate == null) continue;
      if (selected == null || candidate.compareFreshness(selected) >= 0) {
        selected = candidate;
        accepted = true;
      }
    }
    var persisted = true;
    if (accepted && selected != null) {
      try {
        await _cache.write(selected);
      } on AppFailure {
        persisted = false;
      }
      _current = selected;
    }
    return MepRefreshResult(
      quote: selected,
      usedNetwork: accepted,
      persisted: persisted,
      policyPersisted: policyPersisted,
      failure: accepted
          ? null
          : failure ??
                (selected == null && attempted
                    ? const AppFailure(AppFailureKind.noData)
                    : null),
    );
  }

  bool _canAttempt(ProviderRefreshRecord record, DateTime now) {
    if (record.blockedUntilUtc?.isAfter(now) == true) return false;
    final last = record.lastAttemptAtUtc;
    return last == null ||
        last.isAfter(now) ||
        now.difference(last) >= const Duration(minutes: 5);
  }

  DateTime? _blockUntil(AppFailure failure, DateTime now) {
    if (failure.kind == AppFailureKind.rateLimited ||
        failure.kind == AppFailureKind.authentication) {
      return now.add(failure.retryAfter ?? const Duration(minutes: 20));
    }
    return null;
  }
}
