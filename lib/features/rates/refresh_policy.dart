class ProviderRefreshRecord {
  const ProviderRefreshRecord({this.lastAttemptAtUtc, this.blockedUntilUtc});

  final DateTime? lastAttemptAtUtc;
  final DateTime? blockedUntilUtc;

  ProviderRefreshRecord copyWith({
    DateTime? lastAttemptAtUtc,
    DateTime? blockedUntilUtc,
    bool clearBlock = false,
  }) {
    return ProviderRefreshRecord(
      lastAttemptAtUtc: lastAttemptAtUtc ?? this.lastAttemptAtUtc,
      blockedUntilUtc: clearBlock
          ? null
          : blockedUntilUtc ?? this.blockedUntilUtc,
    );
  }

  Map<String, Object?> toJson() => {
    'lastAttemptAtUtc': lastAttemptAtUtc?.toIso8601String(),
    'blockedUntilUtc': blockedUntilUtc?.toIso8601String(),
  };

  factory ProviderRefreshRecord.fromJson(Map<String, Object?> json) {
    return ProviderRefreshRecord(
      lastAttemptAtUtc: _date(json['lastAttemptAtUtc']),
      blockedUntilUtc: _date(json['blockedUntilUtc']),
    );
  }
}

class RefreshPolicy {
  const RefreshPolicy({
    this.primary = const ProviderRefreshRecord(),
    this.fallback = const ProviderRefreshRecord(),
    this.lastAutomaticAtUtc,
    this.lastManualAtUtc,
    this.fallbackBudgetDayUtc,
    this.fallbackAttemptsToday = 0,
  });

  final ProviderRefreshRecord primary;
  final ProviderRefreshRecord fallback;
  final DateTime? lastAutomaticAtUtc;
  final DateTime? lastManualAtUtc;
  final DateTime? fallbackBudgetDayUtc;
  final int fallbackAttemptsToday;

  RefreshPolicy copyWith({
    ProviderRefreshRecord? primary,
    ProviderRefreshRecord? fallback,
    DateTime? lastAutomaticAtUtc,
    DateTime? lastManualAtUtc,
    DateTime? fallbackBudgetDayUtc,
    int? fallbackAttemptsToday,
  }) {
    return RefreshPolicy(
      primary: primary ?? this.primary,
      fallback: fallback ?? this.fallback,
      lastAutomaticAtUtc: lastAutomaticAtUtc ?? this.lastAutomaticAtUtc,
      lastManualAtUtc: lastManualAtUtc ?? this.lastManualAtUtc,
      fallbackBudgetDayUtc: fallbackBudgetDayUtc ?? this.fallbackBudgetDayUtc,
      fallbackAttemptsToday:
          fallbackAttemptsToday ?? this.fallbackAttemptsToday,
    );
  }

  Map<String, Object?> toJson() => {
    'primary': primary.toJson(),
    'fallback': fallback.toJson(),
    'lastAutomaticAtUtc': lastAutomaticAtUtc?.toIso8601String(),
    'lastManualAtUtc': lastManualAtUtc?.toIso8601String(),
    'fallbackBudgetDayUtc': fallbackBudgetDayUtc?.toIso8601String(),
    'fallbackAttemptsToday': fallbackAttemptsToday,
  };

  factory RefreshPolicy.fromJson(Map<String, Object?> json) {
    final primary = json['primary'];
    final fallback = json['fallback'];
    return RefreshPolicy(
      primary: primary is Map<String, dynamic>
          ? ProviderRefreshRecord.fromJson(primary)
          : const ProviderRefreshRecord(),
      fallback: fallback is Map<String, dynamic>
          ? ProviderRefreshRecord.fromJson(fallback)
          : const ProviderRefreshRecord(),
      lastAutomaticAtUtc: _date(json['lastAutomaticAtUtc']),
      lastManualAtUtc: _date(json['lastManualAtUtc']),
      fallbackBudgetDayUtc: _date(json['fallbackBudgetDayUtc']),
      fallbackAttemptsToday: json['fallbackAttemptsToday'] is int
          ? (json['fallbackAttemptsToday'] as int).clamp(0, 30)
          : 0,
    );
  }
}

DateTime? _date(Object? value) {
  if (value is! String) {
    return null;
  }
  return DateTime.tryParse(value)?.toUtc();
}
