import 'refresh_policy.dart';

class MepRefreshPolicy {
  const MepRefreshPolicy({
    this.primary = const ProviderRefreshRecord(),
    this.fallback = const ProviderRefreshRecord(),
    this.fallbackBudgetDayUtc,
    this.fallbackAttemptsToday = 0,
  });

  final ProviderRefreshRecord primary;
  final ProviderRefreshRecord fallback;
  final DateTime? fallbackBudgetDayUtc;
  final int fallbackAttemptsToday;

  MepRefreshPolicy copyWith({
    ProviderRefreshRecord? primary,
    ProviderRefreshRecord? fallback,
    DateTime? fallbackBudgetDayUtc,
    int? fallbackAttemptsToday,
  }) => MepRefreshPolicy(
    primary: primary ?? this.primary,
    fallback: fallback ?? this.fallback,
    fallbackBudgetDayUtc: fallbackBudgetDayUtc ?? this.fallbackBudgetDayUtc,
    fallbackAttemptsToday: fallbackAttemptsToday ?? this.fallbackAttemptsToday,
  );

  Map<String, Object?> toJson() => {
    'primary': primary.toJson(),
    'fallback': fallback.toJson(),
    'fallbackBudgetDayUtc': fallbackBudgetDayUtc?.toIso8601String(),
    'fallbackAttemptsToday': fallbackAttemptsToday,
  };

  factory MepRefreshPolicy.fromJson(Map<String, dynamic> json) =>
      MepRefreshPolicy(
        primary: json['primary'] is Map<String, dynamic>
            ? ProviderRefreshRecord.fromJson(
                json['primary'] as Map<String, dynamic>,
              )
            : const ProviderRefreshRecord(),
        fallback: json['fallback'] is Map<String, dynamic>
            ? ProviderRefreshRecord.fromJson(
                json['fallback'] as Map<String, dynamic>,
              )
            : const ProviderRefreshRecord(),
        fallbackBudgetDayUtc: DateTime.tryParse(
          json['fallbackBudgetDayUtc'] as String? ?? '',
        )?.toUtc(),
        fallbackAttemptsToday: json['fallbackAttemptsToday'] is int
            ? (json['fallbackAttemptsToday'] as int).clamp(0, 30)
            : 0,
      );
}
