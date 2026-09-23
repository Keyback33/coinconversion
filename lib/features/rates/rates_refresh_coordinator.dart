import '../../shared/app_failure.dart';
import 'exchange_rate_repository.dart';
import 'mep_rate_repository.dart';
import 'refresh_policy.dart';
import 'refresh_policy_store.dart';

class CoordinatedRefreshResult {
  const CoordinatedRefreshResult({
    required this.manualRefreshAvailableAtUtc,
    required this.limited,
    this.policyPersisted = true,
  });
  final DateTime? manualRefreshAvailableAtUtc;
  final bool limited;
  final bool policyPersisted;
}

class RatesRefreshCoordinator {
  RatesRefreshCoordinator({
    required ExchangeRateRepository general,
    required MepRateRepository mep,
    required RefreshPolicyStore policyStore,
    DateTime Function()? nowUtc,
  }) : _general = general,
       _mep = mep,
       _policyStore = policyStore,
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  final ExchangeRateRepository _general;
  final MepRateRepository _mep;
  final RefreshPolicyStore _policyStore;
  final DateTime Function() _nowUtc;
  RefreshPolicy? _policy;
  bool _policyDirty = false;
  Future<CoordinatedRefreshResult>? _inFlight;

  Future<DateTime?> readManualRefreshAvailableAtUtc() async {
    final policy = await _readPolicy();
    return _availableAt(policy, _nowUtc().toUtc());
  }

  Future<CoordinatedRefreshResult> refresh(
    RefreshTrigger trigger, {
    required void Function(RefreshResult?, AppFailure?) onGeneral,
    required void Function(MepRefreshResult?, AppFailure?) onMep,
  }) {
    final active = _inFlight;
    if (active != null) return active;
    final operation = _refresh(trigger, onGeneral: onGeneral, onMep: onMep);
    _inFlight = operation;
    return operation.whenComplete(() {
      if (identical(_inFlight, operation)) _inFlight = null;
    });
  }

  Future<CoordinatedRefreshResult> _refresh(
    RefreshTrigger trigger, {
    required void Function(RefreshResult?, AppFailure?) onGeneral,
    required void Function(MepRefreshResult?, AppFailure?) onMep,
  }) async {
    final now = _nowUtc().toUtc();
    var policyPersisted = true;
    final policy = await _readPolicy();
    final last = trigger == RefreshTrigger.manual
        ? policy.lastManualAtUtc
        : policy.lastAutomaticAtUtc;
    if (last != null &&
        !last.isAfter(now) &&
        now.difference(last) < const Duration(hours: 1)) {
      return CoordinatedRefreshResult(
        manualRefreshAvailableAtUtc: _availableAt(policy, now),
        limited: true,
      );
    }
    final updated = trigger == RefreshTrigger.manual
        ? policy.copyWith(lastManualAtUtc: now)
        : policy.copyWith(lastAutomaticAtUtc: now);
    _policy = updated;
    try {
      await _policyStore.write(updated);
      _policyDirty = false;
    } on AppFailure {
      policyPersisted = false;
      _policyDirty = true;
    }
    await Future.wait([
      () async {
        try {
          onGeneral(
            await _general.refresh(trigger, skipGlobalGuard: true),
            null,
          );
        } on AppFailure catch (failure) {
          onGeneral(null, failure);
        }
      }(),
      () async {
        try {
          onMep(await _mep.refresh(), null);
        } on AppFailure catch (failure) {
          onMep(null, failure);
        }
      }(),
    ]);
    return CoordinatedRefreshResult(
      manualRefreshAvailableAtUtc: _availableAt(updated, now),
      limited: false,
      policyPersisted: policyPersisted,
    );
  }

  Future<RefreshPolicy> _readPolicy() async {
    if (_policyDirty && _policy != null) return _policy!;
    try {
      return _policy = await _policyStore.read();
    } on AppFailure {
      return _policy ?? const RefreshPolicy();
    }
  }

  DateTime? _availableAt(RefreshPolicy policy, DateTime now) {
    final last = policy.lastManualAtUtc;
    if (last == null || last.isAfter(now)) return null;
    final at = last.add(const Duration(hours: 1));
    return at.isAfter(now) ? at : null;
  }
}
